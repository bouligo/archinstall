# Archinstall Scripts

A modular and customizable set of shell scripts to automate the installation of Arch Linux. This project allows you to define your desired system configuration in a template and then "compile" it into a single, standalone shell script that can be easily run from the Arch Linux installation media.

## Features

*   **Modular Architecture:**  Installation steps are broken down into small, reusable modules (e.g., disk partitioning, kernel installation, desktop environment setup).
*   **Customizable:**  Easily choose between different kernels (stable, lts, zen), bootloaders (grub, efistub), and desktop environments (KDE, GNOME) by simply commenting or uncommenting lines.
*   **Standalone Script Generation:** A Python helper script combines your selected modules into one portable script, resolving dependencies and file inclusions.
*   **Pre-configured Defaults:** Includes sensible defaults for partitioning, package selection, and system settings.

## Prerequisites

*   **To generate the script:** A machine with Python 3 installed.
*   **To run the installer:** An Arch Linux Live ISO environment.

## Usage

### 1. Prepare your installation script

First, clone this repository:

```bash
git clone https://github.com/bouligo/archinstall.git
cd archinstall
```

Copy the `template.sh` to a new file. This will be your configuration file.

```bash
cp template.sh my-install.sh
```

Edit `my-install.sh` with your preferred text editor. Review the file and uncomment the modules you want to use, or comment out the ones you don't need.

**Example configuration choices:**
*   **Disk:** `simple.sh` (standard partitions), `lvm.sh`, or `lvm-on-luks.sh`.
*   **Kernel:** `kernel.sh` (stable), `kernel-lts.sh`, etc.
*   **Desktop:** `kde.sh`, `gnome.sh`, or minimal versions.

*Note*: If you cloned this repository from the archiso, you can skip step 2. 

### 2. Generate the standalone script (Optionnal)

Run the Python builder script to merge your configuration and the modules into a single file:

```bash
python3 create_standalone_script.py my-install.sh
```

This will create a file named `my-install-static.sh`.

### 3. Run the installer

Boot your target machine with the Arch Linux Live ISO and transfer the generated `my-install-static.sh` to the live environment (e.g., via SCP, USB drive, or downloading it).

Run the script with the required arguments:

```bash
# Usage: bash script.sh <target_disk> <hostname> <username>

bash my-install-static.sh sda MyArchMachine myuser
```

*   `target_disk`: The block device to install to (e.g., `sda`, `nvme0n1`). **WARNING: This disk will be formatted.**
*   `hostname`: The desired hostname for the computer.
*   `username`: The name of the non-root user to create.


## Disclaimer

**WARNING:** These scripts involve disk partitioning and formatting. **All data on the specified target disk will be destroyed.** Always verify the target disk identifier (`sda`, `nvme0n1`, etc.) before running the script. Use at your own risk.
