# G915 Logitech Keyboard

Currently the only full-size linear mechanical keyboard that satisfies the backlit RGB requirement. Previous Keychron K1 has been discontinued.

Unfortunately as it is a Windows-native keyboard there are a few necessary changes:

* [Remap ALT (i.e. Option) and WINDOWS (i.e. Command)](https://www.reddit.com/r/LogitechG/comments/jlnv8e/logitech_g_hub_mac_os_x_g915_reassigning_keys/)
* [Force MENU to be an additional CTRL key](https://apple.stackexchange.com/questions/173898/repurposing-menu-button-on-windows-keyboards-used-in-os-x/398797#398797)
  * See also: [Apple TN2450](https://developer.apple.com/library/archive/technotes/tn2450/_index.html)

```
hidutil property --set '{"UserKeyMapping":[
  {
    "HIDKeyboardModifierMappingSrc": 0x700000065,
    "HIDKeyboardModifierMappingDst": 0x7000000E4
  }
]}'
```
