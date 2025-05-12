### 编程作业

- 本节要求实现三个系统调用 `sys_linkat、sys_unlinkat、sys_stat` 。

    - `sys_linkat`

        - 更新文件对应`iNode`内容
            - 硬链接数加一
        - 更新目录内容：
            - 新增目录项`DirEntry`：新文件名对应`inode_id`的映射

    - `sys_unlinkat`

        - 更新文件对应`iNode`内容

            - 硬链接数减一

        - 更新目录内容

            - 对应名称的目录项数据被清空

        - 如果硬链接为0，释放相关数据

            - 释放`inode`的关联的数据块和位图

            - 释放`inode`的本身节点和位图

        - 需要新增目录项时优先去找之前被清空数据的目录项，而不是调用`resize`方法

            - 修改`Inode`的`create`方法和中`sys_linkat`新增目录项的逻辑：
            - 先去找因为`sys_unlinkat`已被清空内容的目录项，有的话就不用调用`resize`方法，直接修改将该目录项设置为新增的目录项

    - `sys_stat`
        - 修改数据结构
            - `DiskInode`上新增字段存储硬链接数和`inode `文件所在` inode `编号
        - 为了支持向下转型（downcasting）
            - 为`File trait `添加 `Any` 作为 `supertrait`,
        - 找到对应数据
            - 根据`fd`找到`File`文件，随后向下转型为`OSInode`,通过该数据结构找到对应的文件的`DiskInode`的数据，放入`Stat`中



### chapter6简答作业

stride 算法深入

> stride 算法原理非常简单，但是有一个比较大的问题。例如两个 pass = 10 的进程，使用 8bit 无符号整形储存 stride， p1.stride = 255, p2.stride = 250，在 p2 执行一个时间片后，理论上下一次应该 p1 执行。
>
> - 实际情况是轮到 p1 执行吗？为什么？
>   - **答：**
>     - **不是，p2溢出了，p2的值为4，小于p1，p2继续被调度**
>
> 我们之前要求进程优先级 >= 2 其实就是为了解决这个问题。可以证明， **在不考虑溢出的情况下** , 在进程优先级全部 >= 2 的情况下，如果严格按照算法执行，那么 STRIDE_MAX – STRIDE_MIN <= BigStride / 2。
>
> - 为什么？尝试简单说明（不要求严格证明）。
>   - 答：
>     - STRIDE_MAX – STRIDE_MIN 
>       - =BigStride /min_priority-BigStride /max_priority
>       - =BigStride(1/2-1/max_priority)<=BigStride / 2
> - 已知以上结论，**考虑溢出的情况下**，可以为 Stride 设计特别的比较器，让 BinaryHeap<Stride> 的 pop 方法能返回真正最小的 Stride。补全下列代码中的 `partial_cmp` 函数，假设两个 Stride 永远不会相等。
>
> ```
> use core::cmp::Ordering;
> 
> struct Stride(u64);
> 
> impl PartialOrd for Stride {
>     fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
>         // ...
>         let diff = self.0.wrapping_sub(other.0);
>         // 差值小于Stride一半，就是较大的
>     if diff < (1<<8){
>       Some(Ordering::Greater)
>     } else{
>        Some(Ordering::Less)
>     }
>     }
> }
> 
> impl PartialEq for Stride {
>     fn eq(&self, other: &Self) -> bool {
>         false
>     }
> }
> ```
>
> TIPS: 使用 8 bits 存储 stride, BigStride = 255, 则: `(125 < 255) == false`, `(129 < 255) == true`.



### chapter7简答作业

1. 举出使用 pipe 的一个实际应用的例子。

tips:

- 想想你平时咋使用 linux terminal 的？
  - 例子：筛选指定时间段包含某个关键词的日志
- 如何使用 cat 和 wc 完成一个文件的行数统计？
  - cat Makefile | wc -l

2. 如果需要在多个进程间互相通信，则需要为每一对进程建立一个管道，非常繁琐，请设计一个更易用的多进程通信机制。

   引入消息队列的概念，生产者和消费者，来支持一对多和广播的方式等复杂的通信方式

### 荣誉准则

1. 在完成本次实验的过程（含此前学习的过程）中，我曾分别与 **以下各位** 就（与本次实验相关的）以下方面做过交流，还在代码中对应的位置以注释形式记录了具体的交流对象及内容：

   > *《你交流的对象说明》*

   训练营群聊

2. 此外，我也参考了 **以下资料** ，还在代码中对应的位置以注释形式记录了具体的参考来源及内容：

   > *《你参考的资料说明》*

   rCore-Tutorial-Book 第三版

3. 我独立完成了本次实验除以上方面之外的所有工作，包括代码与文档。 我清楚地知道，从以上方面获得的信息在一定程度上降低了实验难度，可能会影响起评分。

4. 我从未使用过他人的代码，不管是原封不动地复制，还是经过了某些等价转换。 我未曾也不会向他人（含此后各届同学）复制或公开我的实验代码，我有义务妥善保管好它们。 我提交至本实验的评测系统的代码，均无意于破坏或妨碍任何计算机系统的正常运转。 我清楚地知道，以上情况均为本课程纪律所禁止，若违反，对应的实验成绩将按“-100”分计。

