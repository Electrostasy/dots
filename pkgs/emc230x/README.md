# Microchip EMC230x RPM-PWM fan controller driver

The hwmon `emc2305` driver present in Linux 6.1 and later, originally submitted
by NVIDIA, does not have devicetree support nor closed-loop RPM fan control.
The kernel maintainers are unwilling to accept any fan controller drivers with
devicetree bindings until someone creates a "standard" fan controller
devicetree binding. The upstream driver also has many other issues which the
Raspberry Pi people have been trying to fix in their downstream kernel fork.

This is the hwmon `emc230x` driver submitted by Traverse about a week after
NVIDIA's driver, which *just works* (it did not get accepted because NVIDIA's
was [accepted first](https://patchwork.kernel.org/comment/25009646/)).

More information about this driver is available [upstream](https://gitlab.traverse.com.au/ls1088firmware/traverse-sensors/-/tree/78802abc95f625316283e9dce39354621daa745a#microchip-emc230x-family-fan-controllers).

In addition, the Traverse driver originally did not feature PWM fan control nor
device tree based probing, which I have added in this version.
