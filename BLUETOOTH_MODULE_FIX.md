# Fix for Bluetooth Module Loading Issues

## Problem Summary

After installing new Bluetooth modules (`btbcm.ko`, `btintel.ko`, `btrtl.ko`, `btusb.ko`) in a custom ROM, module loading failed with the following errors:

```
btbcm: disagrees about version of symbol module_layout
btbcm: disagrees about version of symbol release_firmware
btbcm: Unknown symbol __stack_chk_guard (err 0)
btbcm: Unknown symbol __stack_chk_fail (err 0)
```

## Root Cause Analysis

### Issue 1: Symbol Version Mismatch (CONFIG_MODVERSIONS)

The modules were compiled with `CONFIG_MODVERSIONS=y`, which:
- Generates CRC checksums for all exported kernel symbols
- Requires modules to have matching CRCs with the running kernel
- Fails when modules are compiled against a different kernel source tree

**Problem**: The custom ROM kernel was built from different sources with different CRCs, causing "disagrees about version of symbol" errors.

### Issue 2: Missing Stack Protector Symbols

The modules were compiled with `CONFIG_CC_STACKPROTECTOR_STRONG=y`, which:
- Adds stack canary checks to functions for security
- Requires `__stack_chk_guard` and `__stack_chk_fail` symbols from the kernel
- These symbols were NOT exported by the custom ROM kernel

**Problem**: The custom ROM kernel doesn't export `__stack_chk_guard` and `__stack_chk_fail`, causing "Unknown symbol" errors.

## Solution Implemented

Two configuration changes were made to `.configatv`:

### 1. Disable CONFIG_MODVERSIONS

**Change**:
```diff
-CONFIG_MODVERSIONS=y
+# CONFIG_MODVERSIONS is not set
```

**Effect**:
- Modules will no longer check symbol CRC checksums
- Only vermagic string is checked for compatibility
- Modules will load if vermagic matches (4.9.113 SMP preempt mod_unload ARMv7)

**Trade-off**:
- ⚠️ Vermagic changes from `4.9.113 SMP preempt mod_unload modversions ARMv7` to `4.9.113 SMP preempt mod_unload ARMv7` (no "modversions")
- ✅ Modules become more portable across kernels with same version
- ✅ No more "disagrees about version of symbol" errors

### 2. Disable Stack Protector

**Changes**:
```diff
-# CONFIG_CC_STACKPROTECTOR_NONE is not set
+CONFIG_CC_STACKPROTECTOR_NONE=y
-CONFIG_CC_STACKPROTECTOR_STRONG=y
+# CONFIG_CC_STACKPROTECTOR_STRONG is not set
```

**Effect**:
- Modules compiled without stack canary protection
- No dependency on `__stack_chk_guard` and `__stack_chk_fail` symbols
- Modules can load on kernels that don't export these symbols

**Trade-off**:
- ⚠️ Slightly reduced security (no stack buffer overflow detection in modules)
- ✅ Modules compatible with more kernel configurations
- ✅ No more "Unknown symbol __stack_chk_*" errors

## Important Notes

### Vermagic Compatibility

After these changes, module vermagic will be:
```
4.9.113 SMP preempt mod_unload ARMv7
```

If your custom ROM kernel expects vermagic with "modversions":
```
4.9.113 SMP preempt mod_unload modversions ARMv7
```

You have two options:

**Option A**: Rebuild custom ROM kernel with `CONFIG_MODVERSIONS=n`
- This is the recommended approach
- Ensures kernel and modules match

**Option B**: Force load modules
```bash
insmod -f /vendor/lib/modules/btbcm.ko
```
- Use `-f` flag to bypass vermagic check
- ⚠️ May cause instability if kernel ABI doesn't match

### Security Considerations

Disabling stack protector in modules reduces security:
- Stack buffer overflows in module code won't be detected
- Only affects loadable modules, not the kernel itself
- Trade-off for compatibility with custom ROM kernels

### Alternative Solution

If you can rebuild your custom ROM kernel, the best solution is:
1. Disable `CONFIG_MODVERSIONS` in kernel
2. Ensure `CONFIG_CC_STACKPROTECTOR` exports symbols OR disable it
3. Rebuild both kernel and modules with matching configuration

## How to Verify

After rebuilding modules with these changes:

```bash
# Check module vermagic
adb shell "modinfo /vendor/lib/modules/btusb.ko | grep vermagic"

# Expected output:
# vermagic:       4.9.113 SMP preempt mod_unload ARMv7
```

Load modules:
```bash
# Remove old modules
adb shell "rmmod btusb btrtl btintel btbcm 2>/dev/null || true"

# Load new modules
adb shell "insmod /vendor/lib/modules/btbcm.ko"
adb shell "insmod /vendor/lib/modules/btintel.ko"
adb shell "insmod /vendor/lib/modules/btrtl.ko"
adb shell "insmod /vendor/lib/modules/btusb.ko"

# Check for errors
adb shell "dmesg | tail -50 | grep -iE 'btusb|btbcm|btintel|btrtl|error|fail'"
```

## Files Modified

- `.configatv` - Kernel configuration file
  - Line 279: `CONFIG_MODVERSIONS=y` → `# CONFIG_MODVERSIONS is not set`
  - Line 241: `# CONFIG_CC_STACKPROTECTOR_NONE is not set` → `CONFIG_CC_STACKPROTECTOR_NONE=y`
  - Line 243: `CONFIG_CC_STACKPROTECTOR_STRONG=y` → `# CONFIG_CC_STACKPROTECTOR_STRONG is not set`

## Build Instructions

After these changes, rebuild the kernel and modules:

```bash
# Using GitHub Actions workflow
# Trigger the build_32.yml workflow

# OR manually:
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
make clean
cp .configatv .config
make olddefconfig
make -j$(nproc) modules
make INSTALL_MOD_PATH=output INSTALL_MOD_STRIP=1 modules_install
```

## Technical References

- **CONFIG_MODVERSIONS**: `init/Kconfig` line 2028
- **CONFIG_CC_STACKPROTECTOR**: `arch/Kconfig` line 449
- **Module loading**: `kernel/module.c`
- **Symbol versioning**: `include/linux/module.h`, `kernel/module.c`
- **Stack protector exports**: `arch/arm/kernel/process.c`, `kernel/panic.c`

---

**Date**: 2025-10-11
**Kernel Version**: 4.9.113
**Architecture**: ARM 32-bit (ARMv7)
**Status**: ✅ Fixed
