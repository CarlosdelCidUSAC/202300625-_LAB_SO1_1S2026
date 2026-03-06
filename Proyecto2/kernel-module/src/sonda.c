#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/sched/signal.h>
#include <linux/sysinfo.h>
#include <linux/mm.h>
#include <linux/sched/mm.h>
#include <linux/fs.h>
#include <linux/path.h>
#include <linux/dcache.h>
#include <linux/slab.h>
#include <linux/pid_namespace.h>
#include <linux/nsproxy.h>

// Definimos el nombre del archivo según los requerimientos
#define PROC_NAME "continfo_pr2_so1_202300625"

/* 
 * Función auxiliar para determinar si un proceso está en un contenedor
 * y extraer información relevante
 */
static int is_container_process(struct task_struct *task, char *buffer, size_t bufsize)
{
    struct pid_namespace *pid_ns;
    struct nsproxy *ns;
    
    buffer[0] = '\0';
    
    // Verificar si el proceso tiene un namespace de PID diferente al init
    rcu_read_lock();
    ns = task->nsproxy;
    if (ns && ns->pid_ns_for_children)
    {
        pid_ns = ns->pid_ns_for_children;
        
        // Si el nivel del namespace es > 0, está en un contenedor
        if (pid_ns->level > 0)
        {
            // Formatear como container: + información del proceso
            snprintf(buffer, bufsize, "container:pid%d_ns%u", 
                     task->pid, pid_ns->ns.inum);
            rcu_read_unlock();
            return 1; // Es un contenedor
        }
    }
    rcu_read_unlock();
    return 0; // No es un contenedor
}

/* * Esta función se ejecuta cada vez que el Daemon en Go o un usuario
 * hace un 'cat' al archivo en /proc. Aquí escribiremos toda la lógica.
 */
static int escribir_info_en_proc(struct seq_file *m, void *v)
{
    struct sysinfo i;
    long total_ram, free_ram, used_ram;
    uint64_t total_ram_kb;

    // Puntero para iterar los procesos
    struct task_struct *task;

    // Variables temporales para la memoria de cada proceso
    unsigned long vsz;
    unsigned long rss;
    unsigned long mem_porcentaje_int;
    unsigned long mem_porcentaje_dec;

    // 1. Cálculo de memoria global
    si_meminfo(&i);
    total_ram = (i.totalram * i.mem_unit) / (1024 * 1024);
    free_ram = (i.freeram * i.mem_unit) / (1024 * 1024);
    used_ram = total_ram - free_ram;

    // Guardamos el total en KB para calcular los porcentajes individuales luego
    total_ram_kb = (i.totalram * i.mem_unit) / 1024;

    // Formato esperado por el parser de GO
    seq_printf(m, "[MEMORIA]\n");
    seq_printf(m, "Total: %ld MB\n", total_ram);
    seq_printf(m, "Libre: %ld MB\n", free_ram);
    seq_printf(m, "Uso: %ld MB\n\n", used_ram);

    // Encabezado de procesos en formato CSV con pipes
    seq_printf(m, "[PROCESOS]\n");
    seq_printf(m, "PID|Nombre|VSZ|RSS|%%RAM|CPU|ComandoID\n");

    // 2. Iteración sobre todos los procesos
    for_each_process(task)
    {
        // Verificamos que el proceso tenga memoria de usuario asignada
        if (task->mm)
        {
            struct mm_struct *mm;
            char cmdline[256] = "";
            char container_info[128] = "";
            int is_container;

            // Calculamos VSZ y RSS en KB usando PAGE_SHIFT
            vsz = task->mm->total_vm << (PAGE_SHIFT - 10);
            rss = get_mm_rss(task->mm) << (PAGE_SHIFT - 10);

            // Cálculo del porcentaje de RAM con 2 decimales usando solo enteros
            // Multiplicamos por 10000 para tener 2 decimales
            unsigned long porcentaje_x10000 = (rss * 10000) / total_ram_kb;
            mem_porcentaje_int = porcentaje_x10000 / 100; // Parte entera
            mem_porcentaje_dec = porcentaje_x10000 % 100; // Parte decimal (2 dígitos)

            // CPU time (aproximación)
            unsigned long cpu_time = task->utime;

            // PRIORIDAD 1: Detectar si es un proceso de contenedor
            is_container = is_container_process(task, container_info, sizeof(container_info));

            if (is_container)
            {
                // Es un proceso de contenedor, usar la información del contenedor
                snprintf(cmdline, sizeof(cmdline), "%s", container_info);
            }
            else
            {
                // No es contenedor, intentar obtener cmdline del proceso
                mm = get_task_mm(task);
                if (mm)
                {
                    // Intentamos leer el exe path
                    if (task->mm->exe_file)
                    {
                        struct path *exe_path = &task->mm->exe_file->f_path;
                        char *pathname = d_path(exe_path, cmdline, sizeof(cmdline));
                        if (!IS_ERR(pathname))
                        {
                            // pathname es válido, copiar
                            int len = 0;
                            char *p = pathname;
                            while (*p && len < sizeof(cmdline) - 1)
                            {
                                cmdline[len++] = *p++;
                            }
                            cmdline[len] = '\0';
                        }
                    }
                    mmput(mm);
                }

                // Si no hay cmdline, usar el nombre del comando
                if (cmdline[0] == '\0')
                {
                    snprintf(cmdline, sizeof(cmdline), "%s", task->comm);
                }
            }

            // Formato CSV con pipes: PID|Nombre|VSZ|RSS|%RAM|CPU|ComandoID
            seq_printf(m, "%d|%s|%lu|%lu|%lu.%02lu|%lu|%s\n",
                       task->pid,
                       task->comm,
                       vsz,
                       rss,
                       mem_porcentaje_int,
                       mem_porcentaje_dec,
                       cpu_time,
                       cmdline);
        }
    }

    return 0;
}

/* * Función que se llama al abrir el archivo /proc.
 * Enlaza la apertura del archivo con nuestra función de escritura.
 */
static int abrir_proc(struct inode *inode, struct file *file)
{
    return single_open(file, escribir_info_en_proc, NULL);
}

/* * Estructura de operaciones del archivo (para kernels 5.6 en adelante).
 * Si usas un kernel muy antiguo (ej. Ubuntu 18.04), esto cambia to file_operations.
 */
static const struct proc_ops proc_fops = {
    .proc_open = abrir_proc,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

/* Función de inicialización: se ejecuta al hacer 'insmod' */
static int __init modulo_init(void)
{
    // Creamos el archivo en /proc con permisos de solo lectura (0444)
    proc_create(PROC_NAME, 0444, NULL, &proc_fops);
    printk(KERN_INFO "Módulo cargado: Archivo /proc/%s creado correctamente.\n", PROC_NAME);
    return 0; // 0 significa que se cargó con éxito
}

/* Función de limpieza: se ejecuta al hacer 'rmmod' */
static void __exit modulo_exit(void)
{
    // Es vital eliminar el archivo antes de descargar el módulo para evitar un Kernel Panic
    remove_proc_entry(PROC_NAME, NULL);
    printk(KERN_INFO "Módulo descargado: Archivo /proc/%s eliminado.\n", PROC_NAME);
}

// Registro de las funciones de inicio y salida
module_init(modulo_init);
module_exit(modulo_exit);

// Metadatos obligatorios para evitar advertencias de "kernel taint"
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Carlos - 202300625");
MODULE_DESCRIPTION("Sonda de Kernel para Telemetria de Contenedores - Proyecto 2 SO1");
