# core

Device tree overlays for the CM3, CM4, CM4S and CM5 carrier boards, packaged
so they install with `apt`.

For now the package contains only the overlays. It copies them to
`/boot/firmware/overlays/` and does nothing else: which of them a board loads
is decided by `config.txt`, and the package does not touch that file.

## Overlays

| Overlay | What it adds |
|---|---|
| `adc_default` | MCP3424 ADC, bus and address as parameters |
| `sc16is740-i2c` | SC16IS740 I2C UART (`ttySC0`), without the phantom gpiochip of `sc16is750-i2c` |
| `mcp23008-i2c` | MCP23008 expander at 0x20, the DIO lines |
| `mcp23008-leds` | MCP23008 expander at 0x21, LED1 and buzzer |
| `led_default` | LEDs and buzzer on direct GPIO |
| `rtc_default` | DS1338 or MCP7941x RTC |
| `can_default` | MCP251x CAN controller on spi0.0 |
| `tpm_default` | Infineon SLB9670 TPM 2.0 |
| `ds2482-i2c` | DS2482-100 1-Wire bridge at 0x18, bus as parameter (needs module `ds2482` in `/etc/modules-load.d`) |
| `i2c6-cm5` | enables RP1 `i2c6` on pins 38/39 and names it `i2c-0` (CM5) |
| `emmc-arasan` | makes the Arasan controller `mmc0`, for eMMC boot (CM3) |
| `disable-sdhci` | disables the SDHCI controller |
| `xhci` | enables the XHCI USB controller |

The parameters of each overlay are documented at the top of its source in
[`overlays/`](overlays/). Examples, as the boards use them:

```ini
dtoverlay=adc_default,addr=0x6c,i2c-path=/soc/i2c@7e205000                   # CM3, CM4, CM4S
dtoverlay=adc_default,addr=0x6c,i2c-path=/axi/pcie@1000120000/rp1/i2c@88000  # CM5
```

## Installation

Download the package from the [releases page](../../releases) and install it:

```sh
sudo apt install ./core_<version>_all.deb
```

The `./` is required; without it apt looks the name up in the repositories.

The overlays take effect after a reboot, and only those that `config.txt`
loads. If `/boot/firmware` was not mounted during installation, the package
says so and installs nothing; mount it and run `sudo dpkg-reconfigure core`.

**Removing** (`apt remove`) leaves the overlays in `/boot/firmware/overlays/`,
because `config.txt` may still load them.

**Purging** (`apt purge`) lists the overlays and asks whether to delete them.
The default is no; when apt runs without a way to ask
(`DEBIAN_FRONTEND=noninteractive`) the files stay. The package does not check
`config.txt`: if a board still loads an overlay you delete, it loses that
hardware after the next restart, and a CM3 booting from eMMC without
`emmc-arasan` does not boot at all. Remove the `dtoverlay=` lines first.

## Repository layout

Each overlay is two files: the source `<name>-overlay.dts` and the compiled
`<name>.dtbo`. The package ships the `.dtbo`. CI recompiles every source and
refuses to release if the result differs from the committed `.dtbo`, so the
two cannot drift apart.

After changing a source, compile it the same way:

```sh
dtc -@ -I dts -O dtb -o overlays/<name>.dtbo overlays/<name>-overlay.dts
```

## Building

```sh
./packaging/build-deb.sh <version> dist
```

Needs only `dpkg-deb`. Pushing a tag `v<version>` makes CI build the package
and attach it to a GitHub release.

## License

GPL-2.0, the license of the Raspberry Pi kernel overlays these are based on.
See [LICENSE](LICENSE).
