#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};



static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0xe1c9223, "seq_lseek" },
	{ 0xbdfb6dbb, "__fentry__" },
	{ 0x92997ed8, "_printk" },
	{ 0xf0fdf6cb, "__stack_chk_fail" },
	{ 0x8c01097f, "init_task" },
	{ 0x2469810f, "__rcu_read_unlock" },
	{ 0x9c1e0140, "get_task_mm" },
	{ 0x5b8239ca, "__x86_return_thunk" },
	{ 0x40c7247c, "si_meminfo" },
	{ 0x902e9281, "seq_read" },
	{ 0x6b427ade, "mmput" },
	{ 0x666e61e9, "remove_proc_entry" },
	{ 0xfcbbf86c, "seq_printf" },
	{ 0x5427731d, "single_release" },
	{ 0x4bb9d59e, "single_open" },
	{ 0xb16f97fe, "d_path" },
	{ 0x8d522714, "__rcu_read_lock" },
	{ 0xf45c3f31, "proc_create" },
	{ 0x656e4a6e, "snprintf" },
	{ 0xbf1981cb, "module_layout" },
};

MODULE_INFO(depends, "");

