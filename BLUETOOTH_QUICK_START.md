# Quick Start Guide: Bluetooth Module Compatibility Fix

## What Was Fixed?

Your Bluetooth modules (btbcm, btintel, btrtl, btusb) were failing to load with these errors:
- "disagrees about version of symbol" - Fixed ✅
- "Unknown symbol __stack_chk_guard" - Fixed ✅
- "Unknown symbol __stack_chk_fail" - Fixed ✅

## The Solution

Two kernel configuration options were changed in `.configatv`:

1. **Disabled CONFIG_MODVERSIONS** - Removes symbol version checking
2. **Disabled CONFIG_CC_STACKPROTECTOR_STRONG** - Removes stack protector dependency

## How to Build Fixed Modules

### Option 1: Using GitHub Actions (Recommended)

1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select "Compilar Kernel 32bits" workflow
4. Click "Run workflow"
5. Wait for build to complete
6. Download the artifacts

### Option 2: Manual Build

```bash
# Clone the repository
git clone https://github.com/jrodales-dev/linux-amlogic.git
cd linux-amlogic

# Install ARM cross-compiler (Ubuntu/Debian)
sudo apt-get install gcc-arm-linux-gnueabihf

# Build
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
cp .configatv .config
make olddefconfig
make -j$(nproc) modules
make INSTALL_MOD_PATH=output INSTALL_MOD_STRIP=1 modules_install
```

Modules will be in: `output/lib/modules/4.9.113*/kernel/drivers/bluetooth/`

## ⚠️ IMPORTANT: Vermagic Compatibility

Your modules now have vermagic:
```
4.9.113 SMP preempt mod_unload ARMv7
```

Your custom ROM kernel may expect:
```
4.9.113 SMP preempt mod_unload modversions ARMv7
```

### If You Get "version magic" Error

You have 3 options:

#### Option A: Force Load (Quick Fix)
```bash
adb shell "insmod -f /vendor/lib/modules/btbcm.ko"
adb shell "insmod -f /vendor/lib/modules/btintel.ko"
adb shell "insmod -f /vendor/lib/modules/btrtl.ko"
adb shell "insmod -f /vendor/lib/modules/btusb.ko"
```

⚠️ Use `-f` flag to bypass version check. May work if ABI is compatible.

#### Option B: Rebuild Custom ROM Kernel (Best Solution)

In your custom ROM kernel source:
1. Set `CONFIG_MODVERSIONS=n` in kernel config
2. Rebuild kernel
3. Flash new kernel
4. Install new modules (no `-f` needed)

#### Option C: Keep MODVERSIONS (Complex)

1. Get `Module.symvers` from your custom ROM kernel build
2. Place it in this kernel source root
3. Rebuild modules
4. Modules will have matching symbol versions

## Testing on Device

```bash
# Push modules to device
adb push output/lib/modules/*/kernel/drivers/bluetooth/*.ko /vendor/lib/modules/

# Remove old modules
adb shell "rmmod btusb btrtl btintel btbcm 2>/dev/null || true"

# Load new modules (use -f if needed)
adb shell "insmod /vendor/lib/modules/btbcm.ko"
adb shell "insmod /vendor/lib/modules/btintel.ko"
adb shell "insmod /vendor/lib/modules/btrtl.ko"
adb shell "insmod /vendor/lib/modules/btusb.ko"

# Check for errors
adb shell "dmesg | tail -50 | grep -iE 'btusb|btbcm|btintel|btrtl'"
```

### Success Indicators

✅ No "disagrees about version of symbol" errors
✅ No "Unknown symbol" errors
✅ Modules load successfully
✅ Bluetooth functionality works

### If It Still Fails

Check `dmesg` output carefully:
```bash
adb shell "dmesg | grep -i bluetooth"
```

Common issues:
- **Vermagic mismatch**: Use `insmod -f` or rebuild kernel
- **Firmware missing**: Check `/vendor/firmware/` for BT firmware files
- **Device node missing**: Check `/dev/hci*` and `/sys/class/bluetooth/`

## Documentation

For detailed technical information, see:
- **BLUETOOTH_MODULE_FIX.md** - Complete technical documentation
- **BLUETOOTH_MODULE_FIX_SUMMARY.md** - Detailed comparison and testing guide

## Security Note

⚠️ **Stack protector is disabled in modules**
- Slightly reduced security (no stack overflow detection in modules)
- Trade-off for compatibility with your custom ROM
- Kernel itself still has stack protection

## Need Help?

If modules still don't load after following this guide:
1. Check you're using the correct kernel version (4.9.113)
2. Verify your custom ROM architecture is ARMv7 (32-bit)
3. Share the complete `dmesg` output when loading modules
4. Check if your custom ROM kernel source is available

---

**Last Updated**: 2025-10-11
**Kernel Version**: 4.9.113
**Architecture**: ARM 32-bit (ARMv7)
