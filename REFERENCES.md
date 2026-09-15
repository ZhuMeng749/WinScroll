# 实现参考与取舍

调研日期：2026-09-15。

## Scroll Reverser

- 仓库：https://github.com/pilotmoon/Scroll-Reverser
- 核心文件：https://github.com/pilotmoon/Scroll-Reverser/blob/master/MouseTap.m
- 上游许可：Apache-2.0。
- 实际查阅 README 和 MouseTap.m。参考事件过滤器的创建、超时恢复、暂停时释放，以及写入行位移会连带改变点位移/定点位移这一细节。
- WinScroll 先读取垂直轴的三个表示，再按行、定点、点位移顺序写回。核心测试验证结果与水平轴不受影响。
- 没有采用其手势监听、更新框架或源文件。1.0.1 修复版增加了 IOHID 负载同步，通过动态符号检测兼容接口可用性。

## LinearMouse

- 仓库：https://github.com/linearmouse/linearmouse
- 配置文档：https://github.com/linearmouse/linearmouse/blob/main/Documentation/Configuration.md
- 参考其将鼠标与触控板分开配置的产品方向。设备级识别、按应用配置、加速和平滑滚动超出本次第一版范围。
- 1.0.1 同时查阅 `LinearMouse/EventView/ScrollWheelEventView.swift` 中对 CoreGraphics 与 IOHID 两层滚动数据的处理方式。WinScroll 的兼容桥接独立实现，不引入其工程或依赖。

## UnnaturalScrollWheels

- 仓库：https://github.com/ther0n/UnnaturalScrollWheels
- 参考其聚焦物理滚轮反转、保留触控板的功能范围。

## Apple 公开 API

- https://developer.apple.com/documentation/coregraphics/cgeventfield/scrollwheeleventiscontinuous
- https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate(tap:place:options:eventsofinterest:callback:userinfo:)
- https://developer.apple.com/documentation/applicationservices/axisprocesstrusted()
- https://developer.apple.com/documentation/servicemanagement/smappservice

## 第一版范围

鼠标中间滚轮反转开关、普通鼠标与触控板区分、开机启动、菜单栏常驻。目标是帮助从 Windows 转向 Mac 的用户保留熟悉的滚轮操作习惯。
