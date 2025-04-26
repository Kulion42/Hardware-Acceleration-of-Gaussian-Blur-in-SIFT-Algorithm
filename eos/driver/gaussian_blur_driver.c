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
MODULE_ALIAS("custom: Gaussian blur IP");

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
	{ .compatible = "main_bram_ctrl", }, // main_bram
	{ .compatible = "gaussian_blur_core", }, // gaussian_blur_core
	{ /* end of list */ },
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
int probe_counter = 0;

//Za svako comaptible polje koje se podudara u drajveru i u stablu uredjaja, probe ce se pokrenuti jednom
static int gaussian_blur_probe(struct platform_device *pdev)
{
	struct resource *r_mem;
	int rc = 0;

	printk(KERN_INFO "Probing\n");

	r_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (!r_mem) 
	{
		printk(KERN_ALERT "gaussian_blur_probe: invalid address\n");
		return -ENODEV;
	}

	
	switch (probe_counter)
	{
		//if(strcmp(pdev->name, "main_bram") == 0) //bolji nacin
		case 0: // main_bram
			main_bram = (struct gaussian_blur_info *) kmalloc(sizeof(struct gaussian_blur_info), GFP_KERNEL);
			if (!main_bram)
			{
				printk(KERN_ALERT "gaussian_blur_probe: Cound not allocate main_bram device\n");
				return -ENOMEM;
			}
			
			main_bram->mem_start = r_mem->start;
			main_bram->mem_end   = r_mem->end;
			if(!request_mem_region(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start+1, DRIVER_NAME))
			{
				printk(KERN_ALERT "gaussian_blur_probe: Couldn't lock memory region at %p\n",(void *)main_bram->mem_start);
				rc = -EBUSY;
				goto error1;
			}
			
			main_bram->base_addr = ioremap(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start + 1);
			if (!main_bram->base_addr)
			{
				printk(KERN_ALERT "gaussian_blur_probe: Could not allocate main_bram iomem\n");
				rc = -EIO;
				goto error2;
			}
			
			probe_counter++;
			printk(KERN_INFO "gaussian_blur_probe: main_bram driver registered\n");
			return 0;
			
			error2:
			release_mem_region(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start + 1);
			
			error1:
			return rc;
		
			break;
			
		//if(strcmp(pdev->name, "gaussian_blur_core") == 0)  //bolji nacin
		case 1:  //gaussian_blur_core

			gaussian_blur_core = (struct gaussian_blur_info *) kmalloc(sizeof(struct gaussian_blur_info), GFP_KERNEL);
			if (!gaussian_blur_core)
			{
				printk(KERN_ALERT "gaussian_blur_probe: Cound not allocate gaussian_blur_core\n");
				return -ENOMEM;
			}
			
			gaussian_blur_core->mem_start = r_mem->start;
			gaussian_blur_core->mem_end   = r_mem->end;
			if(!request_mem_region(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start+1, DRIVER_NAME))
			{
				printk(KERN_ALERT "gaussian_blur_probe: Couldn't lock memory region at %p\n",(void *)gaussian_blur_core->mem_start);
				rc = -EBUSY;
				goto error3;
			}
			
			gaussian_blur_core->base_addr = ioremap(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start + 1);
			if (!gaussian_blur_core->base_addr)
			{
				printk(KERN_ALERT "gaussian_blur_probe: Could not allocate gaussian_blur iomem\n");
				rc = -EIO;
				goto error4;
			}
			
			printk(KERN_INFO "gaussian_blur_probe: gaussian_blur_core driver registered\n");
			return 0;
			
			error4:
			release_mem_region(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start + 1);
			
			error3:
			return rc;
			
			break;
			
		default:
			printk(KERN_INFO "gaussian_blur_probe: Counter has illegal value\n");
			return -1;
	}
	return 0;
}

static int gaussian_blur_remove(struct platform_device *pdev)
{

	//isto kao i kod probe, moze se proveravati ime iz pdev-a
	switch (probe_counter)
	{
		case 0: // main_bram
			printk(KERN_ALERT "gaussian_blur_remove: main_bram platform driver removed\n");
			iowrite32(0, main_bram->base_addr);
			iounmap(main_bram->base_addr);
			release_mem_region(main_bram->mem_start, main_bram->mem_end - main_bram->mem_start + 1);
			kfree(main_bram);
			break;
			
		case 1: // gaussian_blur_core
			printk(KERN_ALERT "gaussian_blur_remove: gaussian_blur_core platform driver removed\n");
			iowrite32(0, gaussian_blur_core->base_addr);
			iounmap(gaussian_blur_core->base_addr);
			release_mem_region(gaussian_blur_core->mem_start, gaussian_blur_core->mem_end - gaussian_blur_core->mem_start + 1);
			kfree(gaussian_blur_core);
			probe_counter--;
			break;
			
		default:
			printk(KERN_INFO "gaussian_blur_remove: Counter has illegal value\n");
			return -1;
	}
	return 0;
}

//****************************Implementacija funkcija za operacije nad fajlovima****************************

static int gaussian_blur_open(struct inode *i, struct file *f)
{
    //printk("gaussian_blur opened\n");
    return 0;
}
static int gaussian_blur_close(struct inode *i, struct file *f)
{
    //printk("gaussian_blur closed\n");
    return 0;
}


//*****//
u32 main_bram_i = 0;
int endRead = 0;
u16 width, height, offset_up, offset_down;
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
  
	if(down_interruptible(&sem))
        	return -ERESTARTSYS;
	
	switch (minor)
	{
		case 0: // main_bram
			while (!ready)
			{
				up(&sem);
				if (wait_event_interruptible(readyQ, (ready == 1)))
						return -ERESTARTSYS;
				if (down_interruptible(&sem))
						return -ERESTARTSYS;
			}

			if (main_bram_i >= width * (height - offset_up - offset_down)) 
            {
                main_bram_i = 0; // reset for next open() call
                up(&sem);
                printk(KERN_INFO "gaussian_blur_read: Reached EOF for minor 0\n");
                return 0;
            }

            main_bram_val = ioread32(main_bram->base_addr + ADDR_FACTOR * (main_bram_i/2));
            len = scnprintf(buff, BUFF_SIZE, "%u ", main_bram_val);

            if (copy_to_user(buf, buff, len))
            {
                up(&sem);
                printk(KERN_ERR "gaussian_blur_read: Copy to user failed (main_bram).\n");
                return -EFAULT;
            }

            main_bram_i += 2;

            up(&sem);
            return len;
		
		case 1: // gaussian_blur_core

			if (*offset > 0)
            {
                up(&sem);
                return 0; //  Very important: if already read once, return EOF
            }

			gaussian_blur_val[0] = ioread32(gaussian_blur_core->base_addr + IMG_WIDTH_REG_OFFSET);
			gaussian_blur_val[1] = ioread32(gaussian_blur_core->base_addr + IMG_HEIGHT_REG_OFFSET); 
			gaussian_blur_val[2] = ioread32(gaussian_blur_core->base_addr + IMG_OFFSET_UP_REG_OFFSET); 
			gaussian_blur_val[3] = ioread32(gaussian_blur_core->base_addr + IMG_OFFSET_DOWN_REG_OFFSET); 
			gaussian_blur_val[4] = ioread32(gaussian_blur_core->base_addr + IMG_OCTAVE_NUM_REG_OFFSET); 
			gaussian_blur_val[5] = ioread32(gaussian_blur_core->base_addr + RESET_REG_OFFSET); 
			gaussian_blur_val[6] = ioread32(gaussian_blur_core->base_addr + START_REG_OFFSET); 
			gaussian_blur_val[7] = ioread32(gaussian_blur_core->base_addr + READY_REG_OFFSET); 

			ready = gaussian_blur_val[7];
			wake_up_interruptible(&readyQ);

			len = scnprintf(buff, BUFF_SIZE, "%u %u %u %u %u %u %u %u ",
                gaussian_blur_val[0], gaussian_blur_val[1], gaussian_blur_val[2], gaussian_blur_val[3],
                gaussian_blur_val[4], gaussian_blur_val[5], gaussian_blur_val[6], gaussian_blur_val[7]);

            if (copy_to_user(buf, buff, len))
            {
                up(&sem);
                printk(KERN_ERR "gaussian_blur_read: Copy to user failed (gaussian_blur_core).\n");
                return -EFAULT;
            }

            *offset += len; // Mark that driver did a read
            up(&sem);
            return len;

		default:

			up(&sem);
            printk(KERN_ERR "gaussian_blur_read: Invalid minor number.\n");
            return -EINVAL;
	}
	
	return len;
}


ssize_t gaussian_blur_write(struct file *pfile, const char __user *buf, size_t length, loff_t *off)
{
	char buff[BUFF_SIZE];
	int minor = MINOR(pfile->f_inode->i_rdev);
	
	//mozda trebaju da budu u16 i u32?
	u32 val = 0;
	u16 pos = 0;

	if(down_interruptible(&sem))
		return -ERESTARTSYS;
	
	if (copy_from_user(buff, buf, length))
		return -EFAULT;
	buff[length]='\0';

	//izvlacim vrednost 2 spojena piksela i poziciju u bram-u
	//hu je za short unsigned
	sscanf(buff, "%u, %hu\n", &val, &pos);
	
	switch (minor)
	{
		case 0: // main_bram
			while (!ready)
			{
				up(&sem);
				if (wait_event_interruptible(readyQ, (ready == 1)))
					return -ERESTARTSYS;
				if (down_interruptible(&sem))
					return -ERESTARTSYS;
			}
			
			//dobijam 32 bitnu vrednost val i nju upisujem na main_bram->base_addr + 4*pos
			iowrite32(val, main_bram->base_addr + ADDR_FACTOR * pos);
			//printk(KERN_INFO "gaussian_blur_write: main_bram[%d] = %d\n", pos+1, (val & 0xFFFF));
			//printk(KERN_INFO "gaussian_blur_write: main_bram[%d] = %d\n", pos, ((val >> 16) & 0xFFFF));
			//**********************************************
			
			break;
	
		case 1: // gaussian_blur_core
			if (pos == RESET_REG_OFFSET)
			{
				iowrite32(0, gaussian_blur_core->base_addr + START_REG_OFFSET);
				iowrite32(1, gaussian_blur_core->base_addr + RESET_REG_OFFSET);
				while(!ioread32(gaussian_blur_core->base_addr + READY_REG_OFFSET));
				iowrite32(0, gaussian_blur_core->base_addr + RESET_REG_OFFSET);
				//printk(KERN_INFO "gaussian_blur_write: RESET DONE!\n");
			}
			else if(pos == START_REG_OFFSET)
			{
				while (!ready)
				{
					up(&sem);
					if (wait_event_interruptible(readyQ, (ready == 1)))
						return -ERESTARTSYS;
					if (down_interruptible(&sem))
						return -ERESTARTSYS;
				}
			
				iowrite32(1, gaussian_blur_core->base_addr + START_REG_OFFSET);
				while(ioread32(gaussian_blur_core->base_addr + READY_REG_OFFSET));
				iowrite32(0, gaussian_blur_core->base_addr + START_REG_OFFSET);
				//printk(KERN_INFO "gaussian_blur_write: STARTED!\n");	
			}
			else
			{
				while (!ready)
				{
					up(&sem);
					if (wait_event_interruptible(readyQ, (ready == 1)))
						return -ERESTARTSYS;
					if (down_interruptible(&sem))
						return -ERESTARTSYS;
				}
				
				iowrite32(val, gaussian_blur_core->base_addr + pos);
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
			break;
			
		default:
			printk(KERN_INFO "gaussian_blur_write: Invalid minor. \n");
	}

	up(&sem);

	return length;
}

//*******************INIT i EXIT funckije drajvera*******************

static int __init gaussian_blur_init(void)
{
	sema_init(&sem,1);

	printk(KERN_INFO "\n");
	printk(KERN_INFO "gaussian_blur driver starting insmod.\n");

	if (alloc_chrdev_region(&my_dev_id, 0, 2, "gaussian_blur_region") < 0)
	{
		printk(KERN_ERR "failed to register char device\n");
		return -1;
	}
	printk(KERN_INFO "char device region allocated\n");

	my_class = class_create(THIS_MODULE,"gaussian_blur_class"); //posle linux 6.4 nije potrebno THIS_MODULE
	//my_class = class_create("gaussian_blur_class");
	if (my_class == NULL)
	{
		printk(KERN_ERR "failed to create class\n");
		goto fail_0;
	}
	printk(KERN_INFO "class created\n");

	if (device_create(my_class, NULL, MKDEV(MAJOR(my_dev_id), 0), NULL, "main_bram_ctrl") == NULL) 
	{
		printk(KERN_ERR "failed to create device main_bram\n");
		goto fail_1;
	}
	printk(KERN_INFO "device created - main_bram\n");


	if (device_create(my_class, NULL, MKDEV(MAJOR(my_dev_id), 1), NULL, "gaussian_blur_core") == NULL) 
	{
		printk(KERN_ERR "failed to create device gaussian_blur_core\n");
		goto fail_2;
	}
	printk(KERN_INFO "device created - gaussian_blur_core\n");

	my_cdev = cdev_alloc();
	my_cdev->ops = &my_fops;
	my_cdev->owner = THIS_MODULE;

	if (cdev_add(my_cdev, my_dev_id, 2) == -1)
	{
		printk(KERN_ERR "failed to add cdev\n");
		goto fail_3;
	}
	printk(KERN_INFO "cdev added\n");
	printk(KERN_INFO "gaussian_blur driver initialized.\n");

	return platform_driver_register(&my_driver);

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
	printk(KERN_INFO "gaussian_blur driver starting rmmod.\n");
	platform_driver_unregister(&my_driver);
	cdev_del(my_cdev);

	device_destroy(my_class, MKDEV(MAJOR(my_dev_id),1));
	device_destroy(my_class, MKDEV(MAJOR(my_dev_id),0));
	class_destroy(my_class);
	unregister_chrdev_region(my_dev_id, 1);
	printk(KERN_INFO "gaussian_blur driver exited.\n");
}

module_init(gaussian_blur_init);
module_exit(gaussian_blur_exit);



