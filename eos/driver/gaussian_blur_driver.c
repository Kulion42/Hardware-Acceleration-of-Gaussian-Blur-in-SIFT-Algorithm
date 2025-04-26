#include <linux/kernel.h>
#include <linux/string.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/types.h>
#include <linux/cdev.h>
#include <linux/kdev_t.h>
#include <linux/uaccess.h>
#include <linux/errno.h>
#include <linux/device.h>
//#include <linux/irq.h>
#include <linux/platform_device.h>  //platform driver
#include <linux/ioport.h>           //ioremap
//#include <asm/io.h>

#include <linux/slab.h>             //kmalloc kfree
#include <linux/io.h>               //iowrite ioread
#include <linux/of_address.h>
#include <linux/of_device.h>
#include <linux/of_platform.h>
#include <linux/version.h>

#include <linux/wait.h>
#include <linux/semaphore.h>

MODULE_AUTHOR ("y24_g10");
MODULE_DESCRIPTION("Test Driver for Gaussian blur IP.");
MODULE_LICENSE("Dual BSD/GPL");
MODULE_ALIAS("custom:Gaussian blur IP");

#define DEVICE_NAME "gaussian_blur"
#define DRIVER_NAME "gaussian_blur_driver"

//Velicina bafera
#define BUFF_SIZE 100

//Adresni ofseti registara u gaussian_blur IP coru
#define IMG_WIDTH_REG_OFFSET 0
#define IMG_HEIGHT_REG_OFFSET 4
#define IMG_OFFSET_UP_REG_OFFSET 8
#define IMG_OFFSET_DOWN_REG_OFFSET 12
#define IMG_OCTAVE_NUM_REG_OFFSET 16
#define RESET_REG_OFFSET 20
#define START_REG_OFFSET 24
#define READY_REG_OFFSET 28

#define ADDR_FACTOR 4

//*******************Prototipovi funkcija************************************
static int gaussian_blur_probe(struct platform_device *pdev);
static int gaussian_blur_open(struct inode *i, struct file *f);
static int gaussian_blur_close(struct inode *i, struct file *f);
static ssize_t gaussian_blur_read(struct file *f, char __user *buf, size_t len, loff_t *offset);
static ssize_t gaussian_blur_write(struct file *f, const char __user *buf, size_t length, loff_t *off);
static int __init gaussian_blur_init(void);
static void __exit gaussian_blur_exit(void);
static int gaussian_blur_remove(struct platform_device *pdev);


//*********************Globalne promenljive*************************************
struct gaussian_blur_info 
{
	unsigned long mem_start;
	unsigned long mem_end;
	void __iomem *base_addr;
};

//cdev struktura cuva operacije i vlasnika "character" drajvera
static struct cdev *my_cdev;

//dev_t tip cuva glavni i sporedni broj nekog uredjaja
static dev_t my_dev_id;

//
static struct class *my_class;

//Potreban je red cekanja zbog prebacivanja procesa
DECLARE_WAIT_QUEUE_HEAD(readyQ);

//Potreban je semafor sa vrednoscu 1 (Isto kao mutex) za zakljucavanje kriticnih sekcija
struct semaphore sem;

//
static struct gaussian_blur_info *main_bram = NULL;
static struct gaussian_blur_info *gaussian_blur_core = NULL;

//file operations struktura cuva pokazivace na funkcije koje se pozivaju pri radu sa drajverom
static struct file_operations my_fops =
{
    .owner = THIS_MODULE,
    .open = gaussian_blur_open,
    .release = gaussian_blur_close,
    .read = gaussian_blur_read,
    .write = gaussian_blur_write
};

//Ovde se navode svi uredjaji za koje se ovaj drajver koristi
static struct of_device_id gaussian_blur_of_match[] = 
{
	{ .compatible = "main_bram_ctrl", }, // main_bram koji smesta sliku
	{ .compatible = "gaussian_blur_core", }, // gaussian_blur IP koji sadrzi statusne i konfiguracione registre
	{}, // Kraj niza <- Obavezan deo!
};

static struct platform_driver my_driver = {
    .driver = 
	{
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table	= gaussian_blur_of_match,
	},
	.probe = gaussian_blur_probe,
	.remove	= gaussian_blur_remove,
};

MODULE_DEVICE_TABLE(of, gaussian_blur_of_match);


//**********************************PROBE i REMOVE funkcije*****************************************

//Za svako comaptible polje koje se podudara u drajveru i u stablu uredjaja, probe ce se pokrenuti jednom
static int gaussian_blur_probe(struct platform_device *pdev)
{
	struct resource *r_mem;
	int rc = 0;

	printk(KERN_INFO "gaussian_blur_probe: Pokrećem probe funkciju\n");

	// Dobavljanje resource-a tipa IORESOURCE_MEM (iz stabla uredjaja)
	r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (!r_mem) 
	{
		printk(KERN_ALERT "gaussian_blur_probe: Nevažeća adresa\n");
		return -ENODEV;
	}

	// Provera da li je u pitanju main_bram_ctrl komponenta
	if (of_device_is_compatible(pdev->dev.of_node, "main_bram_ctrl")) {

		// Alokacija memorije za main_bram struktru
		main_bram = (struct gaussian_blur_info *) kmalloc(sizeof(struct gaussian_blur_info), GFP_KERNEL);
		
		if (!main_bram)
		{
			printk(KERN_ALERT "gaussian_blur_probe: Ne mogu da alociram main_bram strukturu\n");
			return -ENOMEM;
		}
		
		// Popunjavanje početne i krajnje adrese
		main_bram->mem_start = r_mem->start;
		main_bram->mem_end   = r_mem->end;

		// Rezervacija fizičkog memorijskog regiona
		if(!request_mem_region(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start+1, DRIVER_NAME))
		{
			printk(KERN_ALERT "gaussian_blur_probe: Ne mogu da zaključam memorijsku regiju na adresi %p\n", (void *)main_bram->mem_start);
			rc = -EBUSY;
			goto error1; // Ako nije uspelo, idi na grešku
		}
		
		// Mapiranje fizičke adrese u virtuelnu adresu
		main_bram->base_addr = ioremap(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start + 1);
		if (!main_bram->base_addr)
		{
			printk(KERN_ALERT "gaussian_blur_probe: Ne mogu da mapiram main_bram memoriju\n");
			rc = -EIO;
			goto error2; // Ako ioremap nije uspeo
		}
		
		printk(KERN_INFO "gaussian_blur_probe: main_bram drajver registrovan\n");
		return 0;
		
		error2:
		release_mem_region(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start + 1);
		
		error1:
		return rc;
	
	}

	// Provera da li je u pitanju gaussian_blur_core komponenta
	else if (of_device_is_compatible(pdev->dev.of_node, "gaussian_blur_core")) {

		// Alokacija memorije za gaussian_blur_core strukturu
		gaussian_blur_core = (struct gaussian_blur_info *) kmalloc(sizeof(struct gaussian_blur_info), GFP_KERNEL);

		if (!gaussian_blur_core)
		{
			printk(KERN_ALERT "gaussian_blur_probe: Ne mogu da alociram gaussian_blur_core strukturu\n");
			return -ENOMEM;
		}
		
		// Popunjavanje početne i krajnje adrese
		gaussian_blur_core->mem_start = r_mem->start;
		gaussian_blur_core->mem_end   = r_mem->end;

		// Rezervacija fizičkog memorijskog regiona
		if(!request_mem_region(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start+1, DRIVER_NAME))
		{
			printk(KERN_ALERT "gaussian_blur_probe: Ne mogu da zaključam memorijsku regiju na adresi %p\n", (void *)gaussian_blur_core->mem_start);
			rc = -EBUSY;
			goto error3; // Ako nije uspelo, idi na grešku
		}
		
		// Mapiranje fizičke adrese u virtuelnu adresu
		gaussian_blur_core->base_addr = ioremap(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start + 1);
		if (!gaussian_blur_core->base_addr)
		{
			printk(KERN_ALERT "gaussian_blur_probe: Ne mogu da mapiram gaussian_blur_core memoriju\n");
			rc = -EIO;
			goto error4;
		}
		
		printk(KERN_INFO "gaussian_blur_probe: gaussian_blur_core drajver registrovan\n");
		return 0;
		
		error4:
		release_mem_region(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start + 1);
		
		error3:
		return rc;
	}
	else {
		// Ako device nije ni jedan od očekivanih
		printk(KERN_INFO "gaussian_blur_probe: Uređaj nije prepoznat\n");
		return -1;
	}

	return 0;
}

static int gaussian_blur_remove(struct platform_device *pdev)
{
	// Uklanjanje main_bram uređaja
	if (of_device_is_compatible(pdev->dev.of_node, "main_bram_ctrl")) {
		printk(KERN_ALERT "gaussian_blur_remove: main_bram platform drajver uklonjen\n");
		iowrite32(0, main_bram->base_addr);
		iounmap(main_bram->base_addr);
		release_mem_region(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start + 1);
		kfree(main_bram);
	}
	// Uklanjanje gaussian_blur_core uređaja
	else if (of_device_is_compatible(pdev->dev.of_node, "gaussian_blur_core")) {
		printk(KERN_ALERT "gaussian_blur_remove: gaussian_blur_core platform drajver uklonjen\n");
		iowrite32(0, gaussian_blur_core->base_addr);
		iounmap(gaussian_blur_core->base_addr);
		release_mem_region(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start + 1);
		kfree(gaussian_blur_core);
	}
	else {
		printk(KERN_INFO "gaussian_blur_remove: Uređaj nije prepoznat\n");
		return -1;
	}

	return 0;
}

//****************************Implementacija funkcija za operacije nad fajlovima****************************

static int gaussian_blur_open(struct inode *i, struct file *f)
{
    //printk("gaussian_blur otvoren\n");
    return 0;
}
static int gaussian_blur_close(struct inode *i, struct file *f)
{
    //printk("gaussian_blur zatvoren\n");
    return 0;
}


//***Globalne promenljive korišćene za rad sa read i write funkcijama**//
u32 main_bram_i = 0;
u16 width, height = 0, offset_up = 0, offset_down = 0;
int ready = 1;
//*****//

//pfile je otvoren fajl pod drajver interfejsom iz kojeg imamo glavni i sporedni broj
//buf je pokazivac na korisnicku memoriju gde treba da se prosledi procitani podatak
//length je maksimalan broj bajtova koje korisnik zeli da procita
//off je fajl ofset ali se on ne koristi
ssize_t gaussian_blur_read(struct file *pfile, char __user *buf, size_t length, loff_t *offset)
{

	char buff[BUFF_SIZE];
	long int len = 0;
	u32 main_bram_val;
	u16 gaussian_blur_val[8];
	int minor = MINOR(pfile->f_inode->i_rdev);
  
	// Zauzimanje semafora za sinhronizaciju
	if(down_interruptible(&sem))
        	return -ERESTARTSYS;
	
	switch (minor)
	{
		case 0: // main_bram

			// Čekanje da uređaj bude spreman za čitanje
			while (!ready)
			{
				// Otpuštanje semafora za sinhronizaciju
				up(&sem);

				// Čekanje dok se ne ispuni uslov ready == 1 
				if (wait_event_interruptible(readyQ, (ready == 1)))
						return -ERESTARTSYS;

				// Zauzimanje semafora za sinhronizaciju
				if (down_interruptible(&sem))
						return -ERESTARTSYS;
			}

			// Provera da li je dostignut kraj fajla (EOF)
			if (main_bram_i >= width * (height - offset_up - offset_down)) 
            {
                main_bram_i = 0; // Resetovanje za sledeći open() poziv

				// Otpuštanje semafora za sinhronizaciju
                up(&sem);

                printk(KERN_INFO "gaussian_blur_read: Dostignut EOF za minor 0\n");
                return 0;
            }

			// Čitanje vrednosti iz BRAM-a
            main_bram_val = ioread32(main_bram->base_addr + ADDR_FACTOR * (main_bram_i/2));
            len = scnprintf(buff, BUFF_SIZE, "%u ", main_bram_val);

			// Kopiranje podataka korisniku
            if (copy_to_user(buf, buff, len))
            {
				// Otpuštanje semafora za sinhronizaciju
                up(&sem);

                printk(KERN_ERR "gaussian_blur_read: Kopiranje u korisnički prostor nije uspelo (main_bram).\n");
                return -EFAULT;
            }

			// Ažuriranje indeksa za sledeće čitanje
            main_bram_i += 2;

			// Otpuštanje semafora za sinhronizaciju
            up(&sem);

            return len;
		
		case 1: // gaussian_blur_core

			// Ako je ofset već veći od 0, vraćamo EOF
			if (*offset > 0)
            {
				// Otpuštanje semafora za sinhronizaciju
                up(&sem);

                return 0; //  Veoma je važno: ako je već čitan, vraćamo EOF
            }

			// Čitanje registara za podatke o slici i statusima
			gaussian_blur_val[0] = ioread32(gaussian_blur_core->base_addr + IMG_WIDTH_REG_OFFSET);
			gaussian_blur_val[1] = ioread32(gaussian_blur_core->base_addr + IMG_HEIGHT_REG_OFFSET); 
			gaussian_blur_val[2] = ioread32(gaussian_blur_core->base_addr + IMG_OFFSET_UP_REG_OFFSET); 
			gaussian_blur_val[3] = ioread32(gaussian_blur_core->base_addr + IMG_OFFSET_DOWN_REG_OFFSET); 
			gaussian_blur_val[4] = ioread32(gaussian_blur_core->base_addr + IMG_OCTAVE_NUM_REG_OFFSET); 
			gaussian_blur_val[5] = ioread32(gaussian_blur_core->base_addr + RESET_REG_OFFSET); 
			gaussian_blur_val[6] = ioread32(gaussian_blur_core->base_addr + START_REG_OFFSET); 
			gaussian_blur_val[7] = ioread32(gaussian_blur_core->base_addr + READY_REG_OFFSET); 

			// Ažuriranje statusa da li je IP core spreman
			ready = gaussian_blur_val[7];
			wake_up_interruptible(&readyQ);

			// Formatiranje podataka za kopiranje u korisničku memoriju
			len = scnprintf(buff, BUFF_SIZE, "%u %u %u %u %u %u %u %u ",
                gaussian_blur_val[0], gaussian_blur_val[1], gaussian_blur_val[2], gaussian_blur_val[3],
                gaussian_blur_val[4], gaussian_blur_val[5], gaussian_blur_val[6], gaussian_blur_val[7]);

			// Kopiranje podataka korisniku
            if (copy_to_user(buf, buff, len))
            {
				// Otpuštanje semafora za sinhronizaciju
                up(&sem);

                printk(KERN_ERR "gaussian_blur_read: Kopiranje u korisnički prostor nije uspelo (gaussian_blur_core).\n");
                return -EFAULT;
            }

			// Obeležavanje da je čitanje završeno
            *offset += len;

            up(&sem);
            return len;

		default:

			// Otpuštanje semafora za sinhronizaciju
			up(&sem);

            printk(KERN_ERR "gaussian_blur_read: Nevalidan minor broj.\n");
            return -EINVAL;
	}
	
	return len;
}


ssize_t gaussian_blur_write(struct file *pfile, const char __user *buf, size_t length, loff_t *off)
{
	char buff[BUFF_SIZE];
	int minor = MINOR(pfile->f_inode->i_rdev);
	
	// Varijable za vrednosti koje korisnik šalje
	u32 val = 0;
	u16 pos = 0;

	// Zauzimanje semafora za sinhronizaciju
	if(down_interruptible(&sem))
		return -ERESTARTSYS;
	
	// Kopiranje podataka sa korisničkog prostora u kernel
	if (copy_from_user(buff, buf, length))
	{
		// Otpuštanje semafora za sinhronizaciju
		up(&sem);

		// Neuspešno kopiranje u korisnički prostor
		return -EFAULT; 
	}

	buff[length]='\0';

	// Parsiranje vrednosti koje je korisnik poslao (vrednost i pozicija)
	// Proveri da li parsiranje prolazi
	if (sscanf(buff, "%u, %hu\n", &val, &pos) != 2) 
	{
		// Otpuštanje semafora za sinhronizaciju
		up(&sem);

		// Pogrešni ulazni podaci
		return -EINVAL; 
	}
	
	switch (minor)
	{
		case 0: // main_bram

			// Čekanje da uređaj bude spreman za upis
			while (!ready)
			{
				// Otpuštanje semafora za sinhronizaciju
				up(&sem);

				// Čekanje dok se ne ispuni uslov ready == 1 
				if (wait_event_interruptible(readyQ, (ready == 1)))
					return -ERESTARTSYS;

				// Zauzimanje semafora za sinhronizaciju
				if (down_interruptible(&sem))
					return -ERESTARTSYS;
			}
			
			// Upisivanje vrednosti u BRAM
			iowrite32(val, main_bram->base_addr + ADDR_FACTOR * pos);
			
			break;
	
		case 1: // gaussian_blur_core

			if (pos == RESET_REG_OFFSET)
			{
				// Resetovanje IP jezgra
				iowrite32(0, gaussian_blur_core->base_addr + START_REG_OFFSET);
				iowrite32(1, gaussian_blur_core->base_addr + RESET_REG_OFFSET);
				while(!ioread32(gaussian_blur_core->base_addr + READY_REG_OFFSET));
				iowrite32(0, gaussian_blur_core->base_addr + RESET_REG_OFFSET);
				//printk(KERN_INFO "gaussian_blur_write: RESET DONE!\n");
			}
			else if(pos == START_REG_OFFSET)
			{
				// Pokretanje operacije IP jezgra
				while (!ready)
				{
					// Otpuštanje semafora za sinhronizaciju
					up(&sem);

					// Čekanje dok se ne ispuni uslov ready == 1 
					if (wait_event_interruptible(readyQ, (ready == 1)))
						return -ERESTARTSYS;
					
					// Zauzimanje semafora za sinhronizaciju
					if (down_interruptible(&sem))
						return -ERESTARTSYS;
				}
			
				iowrite32(1, gaussian_blur_core->base_addr + START_REG_OFFSET);
				while(ioread32(gaussian_blur_core->base_addr + READY_REG_OFFSET));
				iowrite32(0, gaussian_blur_core->base_addr + START_REG_OFFSET);
				//printk(KERN_INFO "gaussian_blur_write: STARTED!\n");	
			}
			else if(pos == IMG_WIDTH_REG_OFFSET ||
					pos == IMG_HEIGHT_REG_OFFSET ||
					pos == IMG_OFFSET_UP_REG_OFFSET ||
 					pos == IMG_OFFSET_DOWN_REG_OFFSET ||
					pos == IMG_OCTAVE_NUM_REG_OFFSET)
			{
				// Upisivanje u ostale registre
				while (!ready)
				{
					// Otpuštanje semafora za sinhronizaciju
					up(&sem);
					
					// Čekanje dok se ne ispuni uslov ready == 1 
					if (wait_event_interruptible(readyQ, (ready == 1)))
						return -ERESTARTSYS;

					// Zauzimanje semafora za sinhronizaciju
					if (down_interruptible(&sem))
						return -ERESTARTSYS;
				}
				
				iowrite32(val, gaussian_blur_core->base_addr + pos);
				
				// Ažuriranje vrednosti parametara slike
				if (pos == IMG_WIDTH_REG_OFFSET)
					width = val;
				else if (pos == IMG_HEIGHT_REG_OFFSET)
					height = val;
				else if(pos == IMG_OFFSET_UP_REG_OFFSET)
					offset_up = val;
				else if(pos == IMG_OFFSET_DOWN_REG_OFFSET)
					offset_down = val;
				//printk(KERN_INFO gaussian_blur_write: gaussian_blur_core[%d] = %d\n", pos, val);
			} 
			else 
			{
				printk(KERN_ERR "gaussian_blur_write: pogrešna vrednost pos. (pos = %d)\n", pos);
				
				// Otpuštanje semafora za sinhronizaciju
				up(&sem);
				
				return -EINVAL; // Greška: pogrešna vrednost registra
			}

			break;
			
		default:
			printk(KERN_INFO "gaussian_blur_write: Nevalidan minor broj.\n");
	}

	// Otpuštanje semafora za sinhronizaciju
	up(&sem);

	return length;
}

//*******************INIT i EXIT funckije drajvera*******************

static int __init gaussian_blur_init(void)
{
	// Inicijalizacija semafora sa početnom vrednošću 1 (binarni semafor)
	sema_init(&sem,1);

	// Ispisivanje početnih informacija u kernel log
	printk(KERN_INFO "\n");
	printk(KERN_INFO "Pokretanje gaussian_blur drajvera putem insmod.\n");

	// Registracija uređaja u sistemu
	if (alloc_chrdev_region(&my_dev_id, 0, 2, "gaussian_blur_region") < 0)
	{
		printk(KERN_ERR "Neuspešno registrovanje uređaja.\n");
		return -1; // Greška u registraciji
	}
	printk(KERN_INFO "Region za uredjaj je dodeljen.\n");

	// Kreiranje klase uređaja
	my_class = class_create(THIS_MODULE,"gaussian_blur_class");
	if (my_class == NULL)
	{
		printk(KERN_ERR "Neuspešno kreiranje klase uređaja.\n");
		goto fail_0;
	}
	printk(KERN_INFO "Klasa uređaja je kreirana.\n");

	// Kreiranje uređaja za "main_bram_ctrl"
	if (device_create(my_class, NULL, MKDEV(MAJOR(my_dev_id), 0), NULL, "main_bram_ctrl") == NULL) 
	{
		printk(KERN_ERR "Neuspešno kreiranje uređaja main_bram.\n");
		goto fail_1;
	}
	printk(KERN_INFO "Uređaj main_bram je kreiran.\n");

	// Kreiranje uređaja za "gaussian_blur_core"
	if (device_create(my_class, NULL, MKDEV(MAJOR(my_dev_id), 1), NULL, "gaussian_blur_core") == NULL) 
	{
		printk(KERN_ERR "Neuspešno kreiranje uređaja gaussian_blur_core.\n");
		goto fail_2;
	}
	printk(KERN_INFO "Uređaj gaussian_blur_core je kreiran.\n");

	// Alokacija i inicijalizacija cdev strukture
	my_cdev = cdev_alloc();
	// Postavljanje operacija karakterističnog uređaja
	my_cdev->ops = &my_fops;
	my_cdev->owner = THIS_MODULE;

	// Dodavanje cdev u sistem
	if (cdev_add(my_cdev, my_dev_id, 2) == -1)
	{
		printk(KERN_ERR "Neuspešno dodavanje cdev u sistem.\n");
		goto fail_3;
	}

	printk(KERN_INFO "cdev je uspešno dodat.\n");

	printk(KERN_INFO "Gaussian_blur drajver je inicijalizovan.\n");

	// Registracija platformnog drajvera
	return platform_driver_register(&my_driver);

	// Ukoliko dođe do greške, uređaji i resursi se uništavaju
	fail_3:
		device_destroy(my_class, MKDEV(MAJOR(my_dev_id),1));
	fail_2:
		device_destroy(my_class, MKDEV(MAJOR(my_dev_id),0));
	fail_1:
		class_destroy(my_class);
	fail_0:
		unregister_chrdev_region(my_dev_id, 1);
	return -1;
}

static void __exit gaussian_blur_exit(void)
{
	printk(KERN_INFO "Pokretanje gaussian_blur rmmod-a.\n");
	
	// Brisanje registracije platformskog drajvera
	platform_driver_unregister(&my_driver);
	
	// Brisanje cdev objekta
	cdev_del(my_cdev);
	
	// Uništavanje uređaja
	device_destroy(my_class, MKDEV(MAJOR(my_dev_id),1));
	device_destroy(my_class, MKDEV(MAJOR(my_dev_id),0));
	
	// Uništavanje klase uređaja
	class_destroy(my_class);
	
	// Otkazivanje registracije uređaja
	unregister_chrdev_region(my_dev_id, 1);
	
	printk(KERN_INFO "Gaussian_blur drajver je isključen.\n");
}

module_init(gaussian_blur_init);
module_exit(gaussian_blur_exit);
