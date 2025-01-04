# SkyPi Nix

## Quick Start: Building the Bootloader

To build the bootloader images for the ROCK5 ITX board, run:

```bash
# Install required dependencies through nix-shell
cd firmware
nix-shell --run ./build-bootloader.sh
```

This will generate three files in `firmware/output/`:
- `idbloader.img` - Initial bootloader (SPL + DDR init) - Write to SD card at offset 32KB
- `trust.img` - ARM Trusted Firmware + OP-TEE - Write to SD card at offset 24MB
- `u-boot.itb` - U-Boot proper - Write to SD card at offset 8MB

### Writing to SD Card

You can write the bootloader images to your SD card using `dd`. Replace `/dev/sdX` with your SD card device:

```bash
# Write idbloader.img at offset 32KB
dd if=output/idbloader.img of=/dev/sdX seek=64

# Write trust.img at offset 24MB
dd if=output/trust.img of=/dev/sdX seek=49152

# Write u-boot.itb at offset 8MB
dd if=output/u-boot.itb of=/dev/sdX seek=16384
```

⚠️ **Warning**: Be extremely careful with the `dd` command and make sure you're writing to the correct device!

### Build Process

The script performs the following steps:
1. Clones the Rockchip firmware repository (rkbin)
2. Clones the Radxa BSP build tools
3. Builds the initial firmware images (idbloader.img and trust.img)
4. Configures and builds U-Boot for the ROCK5 ITX board
5. Places all files in the `bsp/rkbin` directory 