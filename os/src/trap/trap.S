.altmacro  # 启用宏功能，使得我们可以定义和复用汇编代码片段

.macro SAVE_GP n  # 保存通用寄存器的宏
    sd x\n, \n*8(sp)  # 将寄存器 x\n 保存到栈顶 (sp)
.endm

.macro LOAD_GP n  # 加载通用寄存器的宏
    ld x\n, \n*8(sp)  # 从栈顶 (sp) 加载值到寄存器 x\n
.endm

.section .text  # 开始定义文本段，存放代码部分
.globl __alltraps  # 定义全局符号 __alltraps
.globl __restore  # 定义全局符号 __restore
.align 2  # 将代码对齐到 4 字节

__alltraps:
    csrrw sp, sscratch, sp  # 将 sp 寄存器的值保存到 sscratch 寄存器，并交换它们，sscratch 现在指向用户栈，sp 指向内核栈
    # allocate a TrapContext on kernel stack
    addi sp, sp, -34*8  # 分配 34 个 8 字节空间（用于保存寄存器的值）

    # save general-purpose registers
    sd x1, 1*8(sp)  # 保存寄存器 x1 到内核栈
    # skip sp(x2), we will save it later  # 跳过保存 sp (x2)，稍后再保存
    sd x3, 3*8(sp)  # 保存寄存器 x3 到内核栈
    # skip tp(x4), application does not use it  # 跳过保存 tp (x4)，应用程序不使用该寄存器
    # save x5~x31
    .set n, 5  # 设置 n 为 5，表示我们将从寄存器 x5 开始保存
    .rept 27  # 重复 27 次，即保存寄存器 x5 到 x31
        SAVE_GP %n  # 调用 SAVE_GP 宏保存寄存器 x5 到 x31
        .set n, n+1  # 更新 n 的值
    .endr

    # 可以自由使用 t0/t1/t2 寄存器，因为它们已保存到内核栈
    csrr t0, sstatus  # 获取 sstatus 寄存器的值
    csrr t1, sepc  # 获取 sepc 寄存器的值
    sd t0, 32*8(sp)  # 保存 sstatus 到栈中
    sd t1, 33*8(sp)  # 保存 sepc 到栈中

    # read user stack from sscratch and save it on the kernel stack
    csrr t2, sscratch  # 获取 sscratch 寄存器的值（指向用户栈）
    sd t2, 2*8(sp)  # 保将寄存器 t2 中存储的值（即用户栈指针）保存到栈中。

    # set input argument of trap_handler(cx: &mut TrapContext)
    mv a0, sp  # 将当前的栈指针（指向 TrapContext）传递给 trap_handler 函数的参数 a0
    # 在陷阱处理程序（trap_handler）中，我们需要访问当前的 Trap 上下文。Trap 上下文通常保存在内核栈中（例如 TrapContext 结构体）。
    call trap_handler  # 调用 trap_handler 处理陷阱

__restore:
    # case1: start running app by __restore
    # case2: back to U after handling trap

    mv sp, a0  # 恢复栈指针，a0 存储的是处理完陷阱后应该返回的栈指针（指向用户栈）
    # now sp->kernel stack(after allocated), sscratch->user stack
    # restore sstatus/sepc
    ld t0, 32*8(sp)  # 从栈中加载 sstatus 的值
    ld t1, 33*8(sp)  # 从栈中加载 sepc 的值
    ld t2, 2*8(sp)  # 从栈中加载用户栈的指针

    csrw sstatus, t0  # 恢复 sstatus 寄存器的值
    csrw sepc, t1  # 恢复 sepc 寄存器的值
    csrw sscratch, t2  # 恢复 sscratch 寄存器的值

    # restore general-purpose registers except sp/tp
    ld x1, 1*8(sp)  # 恢复寄存器 x1 的值
    ld x3, 3*8(sp)  # 恢复寄存器 x3 的值
    .set n, 5  # 设置 n 为 5，表示从寄存器 x5 开始恢复
    .rept 27  # 重复 27 次，恢复寄存器 x5 到 x31
        LOAD_GP %n  # 调用 LOAD_GP 宏恢复寄存器 x5 到 x31
        .set n, n+1  # 更新 n 的值
    .endr

    # release TrapContext on kernel stack
    addi sp, sp, 34*8  # 释放栈上分配的 TrapContext 空间，恢复栈指针

    # now sp->kernel stack, sscratch->user stack
    csrrw sp, sscratch, sp  # 恢复 sp，设置回用户栈（sscratch 存储的是原来的用户栈指针）
    sret  # 返回到用户模式
