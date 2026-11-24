# ISD-R AID compatibility sources

CellDock tries a candidate only when it can open the application and read a
valid numeric EID. A selectable AID alone is not enough to classify a card as
an eUICC. A brand label describes where an AID was observed; it does not prove
who manufactured a particular card.

| Variant | ISD-R AID | Evidence |
|---|---|---|
| GSMA standard | `A0000005591010FFFFFFFF8900000100` | GSMA SGP.02 v4.3, section 2.2.3; Osmocom eUICC manual |
| eSIM.me | `A0000005591010000000008900000300` | OpenEUICC default list; EasyLPAC source |
| 5ber | `A0000005591010FFFFFFFF8900050500` | OpenEUICC default list; EasyLPAC source |
| XeSIM | `A0000005591010FFFFFFFF8900000177` | OpenEUICC default list; EasyLPAC source |
| LinksField | `A000000559104C696E6B736669656C64` | OpenEUICC commit `d40b839911` and current default list |
| eSTK.me SE0 | `A06573746B6D65FFFF4953442D522030` | OpenEUICC vendor implementation; Osmocom eUICC manual |
| eSTK.me SE1 | `A06573746B6D65FFFF4953442D522031` | OpenEUICC vendor implementation; Osmocom eUICC manual |
| eSTK.me AUX | `A06573746B6D65FFFFFFFF4953442D52` | OpenEUICC default list; Osmocom marks it deprecated |
| eSIM.me field variant | `A0000005591010000000890000000300` | Retained for compatibility with existing field data; not in the current OpenEUICC default list |
| GlocalMe/Tianyu field variant | `A0000006281010FFFFFFFF8900000100` | Retained from an observed vendor application; not in the current OpenEUICC default list |

Primary and maintained references:

- GSMA SGP.02 v4.3: <https://www.gsma.com/esim/wp-content/uploads/2023/02/SGP.02-v4.3.pdf>
- Osmocom OEM applet IDs: <https://euicc-manual.osmocom.org/docs/lpa/applet-id-oem/>
- OpenEUICC current source: <https://gitea.angry.im/PeterCxy/OpenEUICC/src/branch/master/app-common/src/main/java/im/angry/openeuicc/util/PreferenceUtils.kt>
- OpenEUICC LinksField change: <https://git.ac/mirror/OpenEUICC/commit/d40b8399114b0b5a665680adfdd0c8ad49ed11fc>
- EasyLPAC source: <https://github.com/creamlike1024/EasyLPAC/blob/master/config.go>

The search also covered 9eSIM/SIMLink, JMP, EIOTClub and mainstream eUICC
manufacturers. No reliable, distinct alternate ISD-R AID was published for
those products. GSMA-compliant products are already covered by the standard
entry, so duplicate entries are intentionally not added.
