# Partition Configuration Fix for Android 9 Pie USB Burning Tool

## Problem Summary

When flashing Android 9 Pie custom ROM with the newly compiled kernel using USB Burning Tool, the process was failing specifically at the vendor partition. The root cause was an incorrect partition layout in the custom device tree files.

## Files Modified

- `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi`

## Root Causes Identified

### 1. Missing Firmware Configuration Include
The custom partition file was missing the critical include:
```dts
#include "firmware_normal.dtsi"
```

This include provides:
- Proper vbmeta verification configuration with the correct parts list: `"vbmeta,boot,system,vendor"`
- Android fstab (filesystem table) definitions for system, vendor, odm, and product partitions
- Mount flags and filesystem manager flags required by Android

### 2. Incorrect Partition Sizes
The partition sizes didn't match the Android 9 Pie standard layout:

| Partition | Wrong Size | Correct Size | Description |
|-----------|------------|--------------|-------------|
| ODM       | 0x10000000 (256MB) | 0x8000000 (128MB) | ODM-specific customizations |
| System    | 0x74000000 (1.8GB) | 0x50000000 (1.25GB) | Android system partition |

These incorrect sizes caused the subsequent partitions (including vendor) to be positioned incorrectly, causing USB Burning Tool to fail when trying to flash them.

### 3. Incorrect Vbmeta Parts List
The custom file had its own firmware section with an incomplete vbmeta parts list:
```dts
parts = "boot,system,vendor";  // Missing "vbmeta" itself!
```

The correct configuration (from `firmware_normal.dtsi`) includes:
```dts
parts = "vbmeta,boot,system,vendor";  // Includes vbmeta partition
```

## Changes Made

### 1. Added Firmware Include
Added the missing include at the top of the file:
```dts
#include "firmware_normal.dtsi"
```

### 2. Fixed Partition Sizes
Updated partition sizes to match Android Pie 32-bit standard (`partition_mbox_normal_P_32.dtsi`):
```dts
odm:odm {
    pname = "odm";
    size = <0x0 0x8000000>;      // Changed from 0x10000000
    mask = <1>;
};
system:system {
    pname = "system";
    size = <0x0 0x50000000>;     // Changed from 0x74000000
    mask = <1>;
};
```

### 3. Removed Duplicate Firmware Section
Removed the custom firmware section since it's now properly included from `firmware_normal.dtsi`.

### 4. Code Formatting
Standardized code formatting to match the reference file for consistency.

## Partition Layout Order (Android 9 Pie)

The correct partition order for Android 9 Pie on Amlogic GXL platforms is:

```
part-0:  logo      (8MB)
part-1:  recovery  (24MB)
part-2:  misc      (8MB)
part-3:  dtbo      (8MB)
part-4:  cri_data  (8MB)
part-5:  param     (16MB)
part-6:  boot      (16MB)
part-7:  rsv       (16MB)
part-8:  metadata  (16MB)    ← Android 9 addition
part-9:  vbmeta    (2MB)     ← Android 9 addition
part-10: tee       (32MB)
part-11: vendor    (256MB)   ← The partition that was failing
part-12: odm       (128MB)
part-13: system    (1.25GB)
part-14: product   (128MB)   ← Android 9 addition
part-15: cache     (1.1GB)
part-16: data      (remaining space)
```

## Why USB Burning Tool Was Failing

USB Burning Tool expects partitions to be at specific offsets in the flash memory. When the partition table in the kernel DTB doesn't match what the tool expects, it can fail. The issues were:

1. **Wrong partition sizes**: ODM and System partitions had incorrect sizes, causing all subsequent partitions (including vendor) to be at wrong offsets
2. **Missing vbmeta verification**: Without proper vbmeta configuration, Android's Verified Boot was misconfigured
3. **No fstab definitions**: Missing mount point definitions for vendor and other partitions

## How to Compile the Fixed Kernel

### Prerequisites
- ARM cross-compiler toolchain (e.g., gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf)
- Linux kernel source with the fix applied

### Build Steps

1. Set up the cross-compiler:
```bash
export CROSS_COMPILE=/opt/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
```

2. Configure for 32-bit ARM:
```bash
make ARCH=arm meson64_a32_defconfig
```

3. Build only the custom DTB:
```bash
make ARCH=arm gxl_p212_2g_custom.dtb
```

4. Or build the full kernel with all DTBs:
```bash
make ARCH=arm -j$(nproc)
```

### Output Location
The compiled DTB will be at:
```
arch/arm/boot/dts/amlogic/gxl_p212_2g_custom.dtb
```

## Testing the Fix

After compiling the kernel with the fixed partition configuration:

1. Flash the new kernel image and DTB to your TV box using USB Burning Tool
2. The flashing process should now complete successfully without errors at the vendor partition
3. After first boot, verify partitions are mounted correctly:
```bash
adb shell mount | grep -E "(system|vendor|odm|product)"
```

Expected output should show all partitions mounted as read-only:
```
/dev/block/system on /system type ext4 (ro,...)
/dev/block/vendor on /vendor type ext4 (ro,...)
/dev/block/odm on /odm type ext4 (ro,...)
/dev/block/product on /product type ext4 (ro,...)
```

## Technical Details

### Partition Mask Values
- `mask = <1>`: Normal partition
- `mask = <2>`: Parameter partition (writable configuration)
- `mask = <4>`: Data partition (user data, expandable)

### Size Format
Partition sizes are specified in hexadecimal:
- `0x800000` = 8MB
- `0x1000000` = 16MB
- `0x8000000` = 128MB
- `0x10000000` = 256MB
- `0x50000000` = 1.25GB (1280MB)

### Reference Files
- `arch/arm/boot/dts/amlogic/partition_mbox_normal_P_32.dtsi` - Standard Android Pie 32-bit layout
- `arch/arm/boot/dts/amlogic/firmware_normal.dtsi` - Standard firmware configuration
- `arch/arm/boot/dts/amlogic/gxl_p212_2g_custom.dts` - Main device tree file

## Additional Notes

### Why Android 9 Pie Has More Partitions
Android 9 introduced:
- **metadata**: Stores encryption metadata for File-Based Encryption (FBE)
- **vbmeta**: Contains Verified Boot metadata for secure boot chain
- **product**: Separates device-specific product customizations from system

### Compatibility
This fix is specifically for:
- Android 9 Pie custom ROMs
- Amlogic GXL chipset (S905X, S905W, etc.)
- 32-bit ARM architecture (`arm` not `arm64`)
- TV boxes using the p212 reference design with 2GB RAM

### If You Still Have Issues
If flashing still fails after applying this fix:
1. Verify you're using the correct USB Burning Tool version for your device
2. Check that your custom ROM's partition layout matches this DTB configuration
3. Ensure your TV box has sufficient storage (minimum 8GB recommended)
4. Try using a different USB cable or port (USB 2.0 is more reliable than USB 3.0 for flashing)

## References

- [Amlogic USB Burning Tool Documentation](https://forum.armbian.com/topic/12162-amlogic-usb-burning-tool/)
- [Android Verified Boot 2.0](https://source.android.com/security/verifiedboot/avb)
- [Linux Device Tree Documentation](https://www.kernel.org/doc/Documentation/devicetree/usage-model.txt)
