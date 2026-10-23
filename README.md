# Uncharted: The Nathan Drake Collection for Linux

**Native Linux port of Uncharted 1, 2 and 3 from the PS4 collection, running natively without Wine or Proton.**  
Forked from [SuperMedo/uncharted_pc](https://github.com/Supermedo/uncharted_pc) by [AdilDevStuff](https://github.com/AdilDevStuff).

Same concept as [Bloodborne PC (bbport)](https://github.com/deadinside28/bloodborne_pc): the original PS4 x86-64 code runs directly on Linux, and the graphics commands are translated directly to Vulkan via [shadPS4](https://github.com/shadps4-emu/shadPS4)'s video core.

> [!NOTE]
> **No game files are included.** You need your own decrypted dump of the collection (CUSA02343, CUSA02320, etc.: the folder containing `eboot.bin`, `big2-ps4_Shipping.elf`, `big3-ps4_Shipping.elf`, `sce_sys`, `u1data`, `u2data`, and `u3data`).  
> This project is not affiliated with Sony Interactive Entertainment or Naughty Dog.

---

## Features

- **Native Linux Execution**: Runs directly as native Linux ELF executables (`bb-probe` + `libbbgpu.so`) without Wine or Proton overhead.
- **All Three Games in One Launcher**: Seamlessly choose and switch between *Drake's Fortune*, *Among Thieves*, and *Drake's Deception*.
- **High Frame Rates**: 60 FPS (original PS4 target) or 120 FPS+ (higher rates are experimental).
- **Anti-Aliasing & Upscalers**: TAA, AMD FSR 1, AMD FSR 3.1, AMD FSR 4, and Bilinear scaling.
- **Frame Generation**: AMD FSR 3 Frame Generation on any Vulkan-compatible GPU.
- **Full Input Remapping**: Keyboard, mouse, and controllers (DualShock 4, DualSense, Xbox, Switch Pro, etc.) with simultaneous input.
- **Raw Mouse Input & Dynamic Prompts**: Raw mouse aiming and camera look, with in-game button prompts automatically adapting to your active keyboard layout (QWERTY, AZERTY, QWERTZ) and switching dynamically when you grab a controller.
- **Desktop & Menu Integration**: Add the game to your Linux application menu (app grid/launcher) or desktop with one click.

---

## Requirements

- **Operating System**: 64-bit Linux distribution (Arch Linux, Ubuntu 22.04+, Fedora 38+, Debian 12+, NixOS, etc.).
- **Processor (CPU)**: 
  - Intel Core 4th generation (Haswell) or newer, AMD Ryzen, or AMD FX (AVX, BMI1, LZCNT support).
- **Graphics Card (GPU)**: 
  - Vulkan 1.3 compatible GPU with modern drivers (Mesa RADV / AMDGPU, NVIDIA proprietary 535+, or Intel Mesa ANV).
  - **6 GB VRAM or more** recommended. 4 GB cards (GTX 1650, RX 570) should keep Anti-aliasing and Frame Generation off to prevent VRAM exhaustion.
- **Memory**: At least 8 GB RAM + swap space.

---

## Dependencies & Installation

### Arch Linux / Manjaro
```bash
sudo pacman -S --needed base-devel cmake ninja pkgconf \
    vulkan-headers vulkan-icd-loader sdl3 ffmpeg miniupnpc \
    boost fmt robin-map zydis python tk
```

### Ubuntu / Debian (24.04+)
```bash
sudo apt install build-essential cmake ninja-build pkg-config \
    libvulkan-dev libsdl3-dev libavcodec-dev libavutil-dev \
    libminiupnpc-dev libboost-dev libfmt-dev python3 python3-tk
```

### Fedora
```bash
sudo dnf install gcc-c++ cmake ninja-build pkgconf-pkg-config \
    vulkan-headers vulkan-loader-devel SDL3-devel ffmpeg-free-devel \
    miniupnpc-devel boost-devel fmt-devel python3 python3-tkinter
```

### NixOS
A `shell.nix` is included:
```bash
nix-shell shell.nix --run "bash build.sh"
```

---

## Building from Source

1. **Clone the repository with submodules:**
   ```bash
   git clone --recursive https://github.com/AdilDevStuff/uncharted_pc_linux.git
   cd uncharted_pc_linux
   ```
   *(If already cloned, run `git submodule update --init --recursive`)*

2. **Compile the native binaries:**
   ```bash
   bash build.sh
   ```
   This will build:
   - `out/bb-probe` (Native Linux ELF runner)
   - `out/gpu/libbbgpu.so` (Native Vulkan GPU library)
   - `out/bb-gpu-capabilities` (GPU feature detector)

---

## Running the Game

### Graphical Launcher (Recommended)
```bash
python3 launcher/uncharted_launcher.py
```
- Select your dumped game folder.
- Configure resolution, graphics presets, frame rate, and keybindings.
- Click **PLAY**.

### Adding to the Applications Menu
You can install a `.desktop` shortcut into your system menu (`~/.local/share/applications`):
- From the Launcher UI: Click **Add to Menu** on the main page.
- Or from the terminal:
  ```bash
  python3 launcher/uncharted_launcher.py --add-to-menu
  # Or:
  bash launcher/install-desktop.sh
  ```

### Direct Launch (Headless / Terminal)
```bash
# Launch without opening the launcher window:
python3 launcher/uncharted_launcher.py --play

# Or directly through the runner script:
BB_GAME_DIR="/path/to/CUSA02343" BB_EXE=u3 python3 run.py
```

---

## Known Problems & Troubleshooting

- **Logs & Diagnostics**: Detailed logs are written to `user/last_run.log`.
- **Uncharted 3, Cartagena square (Chapter 2)**: At high frame rates, set Frame Rate to 60 in the Display settings if you encounter stability issues.
- **Uncharted 3 visual glitches**: Single-frame flashing on certain character textures (Sully's shirt) is a known shader translation issue from upstream shadPS4.
- **Older CPUs**: CPUs older than Intel Haswell (3rd gen or earlier) lacking required instruction sets (AVX/LZCNT) cannot run the game yet.
- **Frame rates above 120 FPS**: Considered experimental.

---

## Credits

- **[SuperMedo](https://github.com/Supermedo)** for the original Uncharted PC port.
- **[deadinside28](https://github.com/deadinside28/bloodborne_pc)** for the Bloodborne Linux port (`bbport`).
- **[shadPS4 Team](https://github.com/shadps4-emu/shadPS4)** for the Vulkan video core translation and recompiler.
- **[IFreemz](https://github.com/IFreemz/shadPS4-Bloodborne-DLSS-FSR)** for the Videodec2 implementation and DLSS bridge.
- **Third-Party Libraries**: [FSR-Vulkan](https://github.com/FireBurn/FSR-Vulkan), [LibAtrac9](https://github.com/Thealexbarney/LibAtrac9), [SDL3](https://github.com/libsdl-org/SDL), [FFmpeg](https://ffmpeg.org), [Dear ImGui](https://github.com/ocornut/imgui), [sirit](https://github.com/shadps4-emu/sirit), [magic_enum](https://github.com/Neargye/magic_enum), [xbyak](https://github.com/herumi/xbyak), [VMA](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator).

---

## License

GNU GPL v2 or later ([LICENSE](LICENSE)). Third-party components maintain their respective licenses.
