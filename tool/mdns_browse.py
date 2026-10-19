"""List OpenBikeControl services announced on the local network.

Usage: python -I tool/mdns_browse.py [seconds]
Needs: pip install zeroconf
"""

import sys
import time

from zeroconf import ServiceBrowser, ServiceListener, Zeroconf

SERVICE = "_openbikecontrol._tcp.local."


class Printer(ServiceListener):
    def add_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        info = zc.get_service_info(type_, name, timeout=3000)
        if info is None:
            print(f"found {name} (no details)")
            return
        addresses = ", ".join(info.parsed_addresses())
        print(f"found {name}")
        print(f"  host {info.server}  addresses {addresses}  port {info.port}")
        for key, value in sorted(info.properties.items()):
            print(f"  {key.decode()}={(value or b'').decode()}")

    def update_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        pass

    def remove_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        print(f"removed {name}")


def main() -> None:
    seconds = float(sys.argv[1]) if len(sys.argv) > 1 else 8
    zc = Zeroconf()
    try:
        ServiceBrowser(zc, SERVICE, Printer())
        time.sleep(seconds)
    finally:
        zc.close()


if __name__ == "__main__":
    main()
