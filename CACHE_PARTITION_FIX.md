# Amlogic eMMC Cache Partition Mount Fix

## Problem
Boot failure with error: `E: failed to mount /cache (Invalid argument)`
- Occurs on Amlogic GXL (S905X/S912) systems with eMMC storage
- Only affects new kernel, original kernel works
- Cache partition defined with `mask = <0x2>` (STORE_CACHE) in device tree

## Solution
Fixed `drivers/amlogic/mmc/emmc_partitions.c` to pass partition `mask_flags` during partition creation.

### Changes
1. **Pass mask_flags to partition creation** (Line 947)
2. **Add debug logging** for storage detection, partition validation, and creation

### Build & Test
```bash
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- meson64_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image dtbs -j$(nproc)
```

Check logs after boot:
```bash
dmesg | grep -i "partition\|cache"
```

## Technical Details
See `/tmp/SOLUTION_SUMMARY.md` for complete analysis and testing guide.

## Partition Mask Flags
- `STORE_CODE = 1` (0x1) - System partitions
- `STORE_CACHE = 2` (0x2) - Cache partition
- `STORE_DATA = 4` (0x4) - Data partition
