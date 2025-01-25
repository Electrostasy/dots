// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Microchip (formerly SMSC) EMC230X family RPM fan controller driver
 * For EMC2301/2/5 controllers
 * Copyright (C) 2021-2022 Traverse Technologies
 */

/*
 * This driver has two components:
 * - hwmon (read/write fan rpm values)
 * - thermal (set fan rpm speeds for cooling purposes)
 */

#include <linux/err.h>
#include <linux/hwmon.h>
#include <linux/i2c.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/of_device.h>
#include <linux/thermal.h>

#define TACH_HIGH_MASK	GENMASK(12, 5)
#define TACH_LOW_MASK	GENMASK(4, 0)

#define EMC230X_FAN_STALL_STATUS_REG		0x25
#define EMC230X_FAN_SPIN_FAIL_STATUS_REG	0x26
#define EMC230X_FAN_DRIVE_FAIL_STATUS_REG	0x27

#define EMC230X_PWM_FAN_DRIVE_REG(channel)	(0x30 + (channel * 0x10))
#define EMC230X_FAN_CONFIG_REG(channel)		(0x32 + (channel * 0x10))
#define EMC230X_FAN_CONFIG_ENABLE_CLOSED_LOOP	BIT(7)
#define EMC230X_TACH_TARGET_LOW_REG(channel)	(0x3C + (channel * 0x10))
#define EMC230X_TACH_READ_HIGH_REG(channel)	(0x3E + (channel * 0x10))

#define THERMAL_DEVICE_COOLING_MAX_STEPS	7
#define MAX_COOLING_DEV_NAME_LEN 16
/*
 * Factor by equations [2] and [3] from data sheet; valid for fans where the
 * number of edges equals (poles * 2 + 1).
 */
#define FAN_RPM_FACTOR 3932160

struct emc230x_cooling_device {
	struct emc230x_data *parent;
	char name[MAX_COOLING_DEV_NAME_LEN];
	struct thermal_cooling_device *tcdev;
	u8 channel;
	u8 cur_state;
	u16 cooling_step;
	u16 min_rpm;
	u16 max_rpm;
};

struct emc230x_data {
	struct device *hwmon_dev;
	struct i2c_client *i2c_client;
	u8 device_max_channels;
};

static const struct i2c_device_id emc230x_ids[] = {
	{ "emc2301", 1 },
	{ "emc2302", 2 },
	{ "emc2303", 3 },
	{ "emc2305", 5 },
	{ /* sentinel */ }
};

MODULE_DEVICE_TABLE(i2c, emc230x_ids);

static int emc2301_read_fan_tach(struct device *dev,
				 int channel,
				 u16 *tach)
{
	struct emc230x_data *priv = dev_get_drvdata(dev);
	u8 channel_high_register_addr;
	u16 combined_reading;
	u8 channel_bytes[2];
	int bytes_read;

	if ((channel + 1) > priv->device_max_channels)
		return -EINVAL;

	channel_high_register_addr = EMC230X_TACH_READ_HIGH_REG(channel);

	bytes_read = i2c_smbus_read_i2c_block_data(priv->i2c_client,
						   channel_high_register_addr,
						   2, &channel_bytes[0]);
	if (bytes_read < 2) {
		dev_err(dev,
			"%s: error %d reading channel %d tach register",
			__func__, bytes_read, channel);
		return bytes_read;
	}

	/* First byte (register) is the high byte, second low byte */
	combined_reading = ((u16)(channel_bytes[0]) << 5) | (channel_bytes[1] >> 3);

	*tach = combined_reading;

	return 0;
}

static int emc230x_show_fan_rpm(struct device *dev, int channel, long *val)
{
	long fan_rpm;
	u16 channel_tach;
	int ret;

	ret = emc2301_read_fan_tach(dev, channel, &channel_tach);
	if (ret)
		return ret;

	fan_rpm = (FAN_RPM_FACTOR * 2) / channel_tach;
	*val = fan_rpm;

	return 0;
}

static int emc230x_write_fan_rpm_target(struct i2c_client *client,
					int channel, long target_rpm)
{
	int ret;
	u16 target_tach;
	u8 tach_channel_reg_addr;
	u8 tach_bytes[2];

	tach_channel_reg_addr = EMC230X_TACH_TARGET_LOW_REG(channel);
	/* 0 RPM is a special case - writing 0xFFF0 will turn off the fan */
	if (target_rpm == 0) {
		tach_bytes[0] = 0xF0;
		tach_bytes[1] = 0xFF;
	} else {
		target_tach = (FAN_RPM_FACTOR * 2) / target_rpm;
		tach_bytes[0] = (target_tach & TACH_LOW_MASK) << 3;
		tach_bytes[1] = (target_tach & TACH_HIGH_MASK) >> 5;
	}

	ret = i2c_smbus_write_i2c_block_data(client,
					     tach_channel_reg_addr,
					     2, &tach_bytes[0]);
	if (ret != 2)
		return ret;

	return 0;
}

static int emc230x_set_fan_rpm(struct device *dev, int channel, long target_rpm)
{
	struct emc230x_data *priv = dev_get_drvdata(dev);

	if ((channel + 1) > priv->device_max_channels)
		return -ENODEV;

	dev_dbg(dev,
		"%s: setting channel %d rpm to %ld\n",
		__func__, channel, target_rpm);

	return emc230x_write_fan_rpm_target(priv->i2c_client, channel, target_rpm);
}

static int emc230x_read_fan_rpm_target_value(struct i2c_client *client,
					     int channel,
					     long *target_rpm_value)
{
	int ret;
	u8 tach_channel_reg_addr;
	u8 tach_bytes[2];
	u16 combined_reading;
	long rpm_target;

	tach_channel_reg_addr = EMC230X_TACH_TARGET_LOW_REG(channel);
	ret = i2c_smbus_read_i2c_block_data(client,
					    tach_channel_reg_addr,
					    2, &tach_bytes[0]);
	if (ret != 2)
		return ret;

	/* This is different from the RPM speed registers,
	 * the low byte is the first register read
	 */
	if (tach_bytes[1] == 0xFF && tach_bytes[0] == 0xF0) {
		rpm_target = 0;
	} else {
		combined_reading = ((u16)(tach_bytes[1]) << 5) | (tach_bytes[0] >> 3);
		rpm_target = (FAN_RPM_FACTOR * 2) / combined_reading;
	}

	*target_rpm_value = rpm_target;
	return 0;
}

static int emc230x_show_fan_rpm_target(struct device *dev, int channel,
				       long *value)
{
	struct emc230x_data *priv = dev_get_drvdata(dev);

	if ((channel + 1) > priv->device_max_channels)
		return -EINVAL;

	return emc230x_read_fan_rpm_target_value(priv->i2c_client,
						 channel,
						 value);
}

static int emc230x_enable_rpm_control(struct device *dev,
				      struct i2c_client *client,
				      int channel, bool enable)
{
	u8 fan_config_reg_addr;
	u8 fan_config_reg_val;
	int ret;

	fan_config_reg_addr = EMC230X_FAN_CONFIG_REG(channel);

	fan_config_reg_val = i2c_smbus_read_byte_data(client, fan_config_reg_addr);
	if (enable)
		fan_config_reg_val |= EMC230X_FAN_CONFIG_ENABLE_CLOSED_LOOP;
	else
		fan_config_reg_val &= ~(EMC230X_FAN_CONFIG_ENABLE_CLOSED_LOOP);

	ret = i2c_smbus_write_byte_data(client, fan_config_reg_addr, fan_config_reg_val);
	if (ret) {
		dev_err(dev,
			"Unable to write fan configuration register %02X\n",
			fan_config_reg_addr);
		return ret;
	}

	/* If RPM drive not enabled, set PWM cycle (non-closed loop) to 100% */
	if (!enable)
		ret = i2c_smbus_write_byte_data(client,
						EMC230X_PWM_FAN_DRIVE_REG(channel),
						0xFF);

	return ret;
};

static int emc230x_write_rpm_control(struct device *dev,
				     int channel,
				     long value)
{
	struct emc230x_data *priv = dev_get_drvdata(dev);
	bool enable_rpm_control = (value == 1) ? true : false;

	return emc230x_enable_rpm_control(dev, priv->i2c_client,
					  channel,
					  enable_rpm_control);
}

static int emc230x_read_is_rpm_control(struct device *dev,
				       int channel,
				       long *value)
{
	struct emc230x_data *priv = dev_get_drvdata(dev);
	u8 fan_config_reg_addr;
	u32 fan_config_reg_val;

	fan_config_reg_addr = EMC230X_FAN_CONFIG_REG(channel);

	fan_config_reg_val = i2c_smbus_read_byte_data(priv->i2c_client,
						      fan_config_reg_addr);
	if (fan_config_reg_val < 0)
		return fan_config_reg_val;

	if (fan_config_reg_val & EMC230X_FAN_CONFIG_ENABLE_CLOSED_LOOP)
		*value = 1;
	else
		*value = 0;

	return 0;
}


static int emc230x_read_fault(struct i2c_client *client,
			      int channel,
			      long *retval)
{
	int ret;
	u8 fan_mask;
	u8 fan_status_registers[3];
	long fault_value = 0;

	/* Read the three fan fault registers (stall,spin,drive)
	 * consecutively
	 */
	ret = i2c_smbus_read_i2c_block_data(client,
					    EMC230X_FAN_STALL_STATUS_REG,
					    3, &fan_status_registers[0]);
	if (ret != 3)
		return ret;

	fan_mask = (1 << channel);

	if (fan_status_registers[0] & fan_mask) /* Stall */
		fault_value = 1;
	if (fan_status_registers[1] & fan_mask) /* Spin */
		fault_value |= (1<<1);
	if (fan_status_registers[2] & fan_mask) /* Drive */
		fault_value |= (1<<2);
	*retval = fault_value;

	return 0;
}

static int emc230x_show_faults(struct device *dev, int channel,
			       long *value)
{
	struct emc230x_data *priv = dev_get_drvdata(dev);

	return emc230x_read_fault(priv->i2c_client, channel, value);
}

static const struct hwmon_channel_info *emc2301_hwmon_info[] = {
	HWMON_CHANNEL_INFO(fan,
			   HWMON_F_INPUT | HWMON_F_FAULT | HWMON_F_TARGET,
			   HWMON_F_INPUT | HWMON_F_FAULT | HWMON_F_TARGET,
			   HWMON_F_INPUT | HWMON_F_FAULT | HWMON_F_TARGET,
			   HWMON_F_INPUT | HWMON_F_FAULT | HWMON_F_TARGET,
			   HWMON_F_INPUT | HWMON_F_FAULT | HWMON_F_TARGET),
	HWMON_CHANNEL_INFO(pwm,
			   HWMON_PWM_ENABLE,
			   HWMON_PWM_ENABLE,
			   HWMON_PWM_ENABLE,
			   HWMON_PWM_ENABLE,
			   HWMON_PWM_ENABLE),
	NULL
};

static umode_t emc230x_hwmon_is_visible(const void *data,
				  enum hwmon_sensor_types type,
				  u32 attr, int channel)
{
	struct emc230x_data *priv = (struct emc230x_data *)data;

	if ((channel + 1) > priv->device_max_channels)
		return 0;

	switch (type) {
	case hwmon_fan:
		switch (attr) {
		case hwmon_fan_input:
		case hwmon_fan_fault:
			return 0444;
		case hwmon_fan_target:
			return 0644;
		default:
			return 0;
		}
	case hwmon_pwm:
		switch (attr) {
		case hwmon_pwm_enable:
			return 0644;
		default:
			return 0;
		}
	default:
		return 0;
	}
}

static int emc230x_hwmon_read(struct device *dev, enum hwmon_sensor_types type,
			      u32 attr, int channel, long *value)
{
	switch (type) {
	case hwmon_fan:
		switch (attr) {
		case hwmon_fan_input:
			return emc230x_show_fan_rpm(dev, channel, value);
		case hwmon_fan_target:
			return emc230x_show_fan_rpm_target(dev, channel, value);
		case hwmon_fan_fault:
			return emc230x_show_faults(dev, channel, value);
		default:
			return 0;
		}
	case hwmon_pwm:
		switch (attr) {
		case hwmon_pwm_enable:
			return emc230x_read_is_rpm_control(dev, channel, value);
		default:
			return 0;
		}
	default:
		return 0;
	}
}

static int emc230x_hwmon_write(struct device *dev, enum hwmon_sensor_types type,
			u32 attr, int channel, long value)
{
	if (type == hwmon_fan && attr == hwmon_fan_target)
		return emc230x_set_fan_rpm(dev, channel, value);
	else if (type == hwmon_pwm && attr == hwmon_pwm_enable)
		return emc230x_write_rpm_control(dev, channel, value);

	return -EINVAL;
}

static int emc230x_thermal_get_max_state(struct thermal_cooling_device *tcdev,
					 unsigned long *state)
{
	*state = THERMAL_DEVICE_COOLING_MAX_STEPS;
	return 0;
}

static int emc230x_thermal_get_cur_state(struct thermal_cooling_device *tcdev,
					 unsigned long *state)
{
	struct emc230x_cooling_device *cdev = tcdev->devdata;

	*state = cdev->cur_state;

	return 0;
}

static int emc230x_thermal_set_cur_state(struct thermal_cooling_device *tcdev,
					 unsigned long state)
{
	struct emc230x_cooling_device *cdev = tcdev->devdata;
	struct emc230x_data *parent_device = cdev->parent;
	struct i2c_client *client = parent_device->i2c_client;
	int ret;
	u16 fan_rpm;

	if (state > 0)
		fan_rpm = cdev->min_rpm + ((state + 1) * cdev->cooling_step);
	else
		fan_rpm = cdev->min_rpm;

	ret = emc230x_write_fan_rpm_target(client, cdev->channel, fan_rpm);
	if (!ret)
		cdev->cur_state = state;

	return ret;
}

static const struct thermal_cooling_device_ops emc230x_fan_cooling_ops = {
	.get_max_state = emc230x_thermal_get_max_state,
	.get_cur_state = emc230x_thermal_get_cur_state,
	.set_cur_state = emc230x_thermal_set_cur_state
};

/*
 * emc230x_create_fan() - create a thermal device from FDT configuration
 */
static int emc230x_create_fan(struct device *dev,
			      struct device_node *child,
			      struct emc230x_data *priv)
{
	int ret;
	u32 channel;
	u16 min_rpm, max_rpm, cooling_range;
	struct emc230x_cooling_device *faninfo;

	ret = of_property_read_u32(child, "reg", &channel);
	if (ret)
		return ret;

	if ((channel + 1) > priv->device_max_channels)
		return -EINVAL;

	/* If there are any DT attributes introduced that are not
	 * directly related to thermal subsystem integration
	 * (such as configuring PWM modes, or fan pole settings),
	 * they should be processed here before the #cooling-cells
	 * check
	 */
	ret = of_property_count_u32_elems(child, "#cooling-cells");
	if (ret < 1)
		return 0;

	ret = of_property_read_u16(child, "min-rpm", &min_rpm);
	if (ret) {
		dev_err(dev,
			"%s: missing or invalid \"min-rpm\" property (channel=%d,err=%d)\n",
			__func__, channel, ret);
		return ret;
	}

	ret = of_property_read_u16(child, "max-rpm", &max_rpm);
	if (ret) {
		dev_err(dev,
			"%s: missing or invalid \"min-rpm\" property (channel=%d,err=%d)\n",
			__func__, channel, ret);
		return ret;
	}

	faninfo = devm_kzalloc(dev, sizeof(*faninfo), GFP_KERNEL);

	faninfo->parent = priv;
	faninfo->channel = (u8)channel;
	faninfo->min_rpm = min_rpm;
	faninfo->max_rpm = max_rpm;

	cooling_range = max_rpm - min_rpm;
	faninfo->cooling_step = cooling_range / (THERMAL_DEVICE_COOLING_MAX_STEPS+1);
	faninfo->cur_state = THERMAL_DEVICE_COOLING_MAX_STEPS;

	/* Set the maximum fan rpm */
	ret = emc230x_write_fan_rpm_target(priv->i2c_client, channel, max_rpm);
	if (ret)
		return ret;

	/* Enable RPM closed-loop control */
	ret = emc230x_enable_rpm_control(dev, priv->i2c_client, channel, true);
	if (ret)
		return ret;

	snprintf(faninfo->name, MAX_COOLING_DEV_NAME_LEN, "%pOFn%d", child, channel);

	faninfo->tcdev = devm_thermal_of_cooling_device_register(dev, child,
								 faninfo->name,
								 faninfo,
								 &emc230x_fan_cooling_ops);
	dev_info(dev,
		 "channel %d registered as cooling device %d, min/max RPM %d/%d step %d\n",
		 channel, faninfo->tcdev->id, min_rpm, max_rpm, faninfo->cooling_step);

	return 0;
}

static const struct hwmon_ops emc230x_hwmon_ops = {
	.is_visible = emc230x_hwmon_is_visible,
	.read = emc230x_hwmon_read,
	.write = emc230x_hwmon_write,
};

static const struct hwmon_chip_info emc230x_chip_info = {
	.ops = &emc230x_hwmon_ops,
	.info = emc2301_hwmon_info
};

static int emc230x_probe(struct i2c_client *i2c)
{
	struct device *dev = &i2c->dev;
	struct device *hwmon_dev;
	struct device_node *np, *child;
	struct emc230x_data *priv;
	const struct i2c_device_id *dev_id;
	int ret;

	if (!i2c_check_functionality(i2c->adapter, I2C_FUNC_SMBUS_BYTE_DATA |
				     I2C_FUNC_SMBUS_WORD_DATA))
		return -ENODEV;

	priv = devm_kzalloc(dev, sizeof(struct emc230x_data), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	priv->i2c_client = i2c;

	dev_id = i2c_match_id(emc230x_ids, i2c);
	if (!dev_id)
		return -ENODEV;

	priv->device_max_channels = (u32)dev_id->driver_data;

	if (IS_REACHABLE(CONFIG_THERMAL) && dev->of_node) {
		np = dev->of_node;
		for_each_child_of_node(np, child) {
			ret = emc230x_create_fan(dev, child, priv);
			if (ret)
				of_node_put(child);
		}
	}

	hwmon_dev = devm_hwmon_device_register_with_info(dev, i2c->name,
							 priv,
							 &emc230x_chip_info,
							 NULL);
	return PTR_ERR_OR_ZERO(hwmon_dev);
}

static struct i2c_driver emc230x_driver = {
	.class = I2C_CLASS_HWMON,
	.driver = {
		.name = "emc230x",
	},
	.probe = emc230x_probe,
	.id_table = emc230x_ids,
};

module_i2c_driver(emc230x_driver);

MODULE_AUTHOR("Mathew McBride <matt@traverse.com.au>");
MODULE_DESCRIPTION("Microchip EMC230X family PWM RPM fan controller driver");
MODULE_LICENSE("GPL");
