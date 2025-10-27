# Cache Partition Mount Error Fix

## Problem Description

After successfully flashing a custom ROM with modified kernel (ARM 32-bit version) using USB Burning Tool, the system was failing to boot and falling back to the bootloader with the following errors:

```
suporter api: 3
E: failed to mount /cache (Invalid argument)
E: failed to mount /cache/recovery/last_locale
E: failed to mount /cache (Invalid argument)
```

## Root Cause Analysis

The issue was caused by a **missing fstab entry for the cache partition** in the device tree configuration file `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi`.

While the cache partition was properly defined in the partitions section:
```c
cache:cache
{
    pname = "cache";
    size = <0x0 0x46000000>;  // 1120 MB
    mask = <2>;
};
```

It was **missing from the firmware fstab section**, which is required by Android's init system and recovery mode to properly mount the partition.

## Solution Applied

Added the cache partition entry to the fstab section in `partition_mbox_p212_custom.dtsi`:

```diff
      metadata {
        compatible = "android,metadata";
        dev = "/dev/block/metadata";
        type = "ext4";
        mnt_flags = "defaults";
        fsmgr_flags = "wait";
        };
+     cache {
+       compatible = "android,cache";
+       dev = "/dev/block/cache";
+       type = "ext4";
+       mnt_flags = "nosuid,nodev,barrier=1";
+       fsmgr_flags = "wait";
+       };
      };
    };
  };
};
```

### Configuration Details

- **compatible**: `"android,cache"` - Identifies this as the Android cache partition
- **dev**: `"/dev/block/cache"` - Block device path for the cache partition
- **type**: `"ext4"` - Filesystem type (ext4 is standard for Android cache)
- **mnt_flags**: `"nosuid,nodev,barrier=1"` - Mount flags:
  - `nosuid`: Don't allow set-user-ID or set-group-ID bits to take effect
  - `nodev`: Don't interpret character or block special devices
  - `barrier=1`: Enable write barriers for data integrity
- **fsmgr_flags**: `"wait"` - Wait for the partition to be available before continuing boot

## Why This Fix Works

1. **Recovery Mode**: Android recovery reads the device tree fstab to determine which partitions to mount. Without the cache entry, recovery cannot mount `/cache` and fails with "Invalid argument" error.

2. **Boot Process**: The init system uses the fstab to mount partitions during boot. Missing cache entry causes boot to fail or fall back to recovery.

3. **Cache Partition Usage**: The cache partition is used by Android for:
   - Recovery logs (`/cache/recovery/`)
   - OTA update packages
   - Temporary files during updates
   - App cache data (on older Android versions)

## Expected Result

After applying this fix and recompiling the kernel with the corrected device tree:

✅ The system should boot normally without falling back to bootloader  
✅ Recovery mode will successfully mount `/cache`  
✅ Recovery logs will be properly written to `/cache/recovery/`  
✅ OTA updates will work correctly  

## How to Apply

1. **Recompile the Device Tree Blob (DTB)**:
   ```bash
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs
   ```

2. **Recompile the Kernel** (if needed):
   ```bash
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
   ```

3. **Flash the Updated Kernel/ROM**:
   - Use USB Burning Tool with the updated image
   - The DTB file should be: `arch/arm/boot/dts/amlogic/gxl_p212_2g_custom.dtb`

4. **Verify After Boot**:
   ```bash
   # Connect via ADB
   adb shell mount | grep cache
   # Should show: /dev/block/cache on /cache type ext4 (...)
   ```

## Related Files

- **Modified**: `arch/arm/boot/dts/amlogic/partition_mbox_p212_custom.dtsi`
- **Uses This**: `arch/arm/boot/dts/amlogic/gxl_p212_2g_custom.dts`

## Additional Notes

- This fix is specific to non-A/B partition schemes. A/B systems (like `partition_mbox_ab_P_32.dtsi`) don't use a cache partition.
- The cache partition size (1120 MB / 0x46000000 bytes) was already correctly defined and doesn't need to be changed.
- All other partitions (system, vendor, odm, product, metadata) already had fstab entries.

---

**Status**: ✅ Fix applied successfully
