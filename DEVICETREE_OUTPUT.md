# Device Tree Output Structure

This document describes the device tree (DTS/DTB) files included in the build artifacts from the `build_32.yml` workflow.

## Output Directory Structure

The kernel build artifacts include the following DTS/DTB structure:

```
kernel_output/
├── boot/
│   └── zImage                    # Kernel image
├── dtbs/
│   ├── gxl_p212_1g.dtb          # Compiled device tree blobs
│   ├── gxl_p212_1g_buildroot.dtb
│   ├── gxl_p212_1g_hd.dtb
│   ├── gxl_p212_2g.dtb
│   └── gxl_p212_2g_buildroot.dtb
├── dts/
│   ├── original/                 # Original DTS source files
│   │   ├── gxl_p212_1g.dts      # Preserves: comments, includes, formatting
│   │   ├── gxl_p212_1g_buildroot.dts
│   │   ├── gxl_p212_1g_hd.dts
│   │   ├── gxl_p212_2g.dts
│   │   └── gxl_p212_2g_buildroot.dts
│   ├── decompiled/               # DTB decompiled back to DTS
│   │   ├── gxl_p212_1g.dts      # For debugging/verification
│   │   ├── gxl_p212_1g_buildroot.dts
│   │   ├── gxl_p212_1g_hd.dts
│   │   ├── gxl_p212_2g.dts
│   │   └── gxl_p212_2g_buildroot.dts
│   └── includes/                 # DTSI include files
│       ├── mesongxl.dtsi        # Main SoC definition
│       ├── mesongxl_p212-panel.dtsi
│       ├── partition_mbox_normal.dtsi
│       └── meson_drm.dtsi
├── lib/
│   └── modules/                  # Kernel modules
└── logs/
    ├── build_kernel.log
    ├── build_dtbs.log
    └── build_modules.log
```

## File Types Explained

### DTB (Device Tree Blob)
- **Location**: `dtbs/`
- **Purpose**: Binary compiled device tree ready for bootloader use
- **Format**: Binary blob (FDT format)
- **Usage**: Flash this to your device or pass to U-Boot/bootloader

### Original DTS (Device Tree Source)
- **Location**: `dts/original/`
- **Purpose**: Human-readable source files with all original properties
- **Preserves**:
  - Comments and documentation
  - `#include` directives and file structure
  - Original formatting and organization
  - All device properties and configurations
- **Usage**: Reference for understanding device configuration, making modifications

### Decompiled DTS
- **Location**: `dts/decompiled/`
- **Purpose**: DTB converted back to DTS for verification/debugging
- **Note**: Loses original formatting, includes are resolved, comments removed
- **Usage**: Verify what was actually compiled into the DTB

### DTSI (Device Tree Source Include)
- **Location**: `dts/includes/`
- **Purpose**: Include files referenced by the main DTS files
- **Content**: Shared definitions, SoC configurations, peripheral definitions
- **Usage**: Required to fully understand the device tree structure

## Why Both Original and Decompiled DTS?

The workflow provides both versions because:

1. **Original DTS** (`dts/original/`)
   - Contains human-readable comments
   - Shows the logical structure with includes
   - Easier to modify and understand
   - Preserves developer intent

2. **Decompiled DTS** (`dts/decompiled/`)
   - Shows exactly what the DTB contains
   - All includes are resolved
   - Useful for debugging hardware issues
   - Verifies compilation was correct

## Key Properties in DTS Files

Important properties to verify in your device tree:

- `model`: Device model identifier
- `amlogic-dt-id`: Amlogic-specific device tree ID
- `compatible`: Device compatibility strings
- `memory@*`: Memory configuration
- `reserved-memory`: Reserved memory regions
- Device-specific configurations (GPU, display, etc.)

## Making Modifications

To modify the device tree:

1. Edit files in `dts/original/` or the source repository
2. Rebuild using the workflow
3. Compare `dts/original/` with `dts/decompiled/` to verify changes
4. Use the DTB from `dtbs/` for your device

## Notes

- The decompiled DTS files are automatically generated for verification only
- Always base modifications on the original DTS files, not the decompiled versions
- Include files (DTSI) are shared dependencies needed for understanding the full device tree
