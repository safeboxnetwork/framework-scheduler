# Introduction

## Problem Statement
<p align="justify">
Data storage, management, accessibility and security are becoming an ever greater challenge in the modern digital age. Traditional data management methods often cannot keep pace with the growing volume of data and complex security requirements. From another perspective, increasingly intensive large-scale corporate services are being built on the accessibility and storage of user data, which often monopolize the market, limiting users’ choices and increasing privacy risks, if not otherwise, then through continuous service fees or the loss of control over the data, for example by using it for data mining purposes.

In addition to the above, more and better-functioning private data storage and management solutions are appearing on the market, whose goal is to give users back control over their data while ensuring its secure storage and accessibility. These solutions often use decentralized systems that enable distributed storage and management of data, thereby reducing dependence on central service providers and increasing data security. However, in most cases operating these solutions requires significant technical knowledge, which limits their wider adoption, and at the same time can endanger security and availability, since their creators basically implement individual services and may not necessarily be able to meet complex data storage or access requirements.
</p>

**The Safebox can provide an appropriate solution to this.**

## Why We Need a New Approach

<p align="justify">
The Safebox solution is not the first attempt to bring together third‑party standalone or community software service initiatives on a manageable platform. It is also not particularly new that a clean, easy‑to‑understand graphical interface continuously supports users in installing and managing services. In fact, there are many similar initiatives, some of which are open source, while others are closed source. These solutions can meet user needs to varying degrees, but they often lack key features that make the Safebox platform unique and efficient, such as a flexible and customizable template system, built‑in domain management, or multiple geo‑redundant backup options. These provide real advantages for users because if a user undertakes to build their own data management infrastructure, it must represent real value for them: it must be configurable and accessible as desired, understandable and easy to use, and it must not expose them to the risk of data loss.
</p>

## Key Features of the Safebox Platform
<p align="justify">
Fontos hangsúlyozni, a Safebox nem akar egy újabb szoftver telepítő megoldás lenni vagy csak egy újabb felhő alapú tárolási szolgáltatás. Célunk egy olyan jól kezelhető, könnyen érthető szoftver platform létrehozása, amely lehetővé teszi a felhasználók számára, hogy saját adattárolási infrastruktúrát építsenek ki, amely más, nagy szolgáltatók szolgáltatásaival egyenértékű megoldást hoz létre, azok hátrányai nélkül. A Safebox platform főbb jellemzői a következők:

### Remote access

<p align="justify">
A távoli elérés szolgáltatás az egyik legfontosabb jellemzője a Safebox platformnak, amely lehetővé teszi a felhasználók számára, hogy biztonságosan hozzáférjenek adataikhoz és szolgáltatásaikhoz bárhonnan a világon. Ez a funkció gyakorlatilag a nagy szolgáltatók felhő alapú szolgáltatásainak megfelelő kényelmet és hozzáférhetőséget biztosítja anélkül, hogy adataikat meg kellene osztaniuk harmadik felekkel. A távoli elérés titkosított adatfolyamatokon keresztül történik úgy, hogy kihasználva a TCP alapú routing proxy technológiát, amely biztosítja az adatok biztonságát és integritását az átvitel során. Ennek egyik legfontosabb jellemzője, hogy a felhasználók számítógépei nem csak távoli végpopntokká válnak, de már a kezdetekkor, az első közhiteles tanúsítványok létrehozását is a saját számítógépükön végzik, az elkészült, generált tanúsítványok a saját gépeiken jelennek meg, ellenőrizhető módon, és később is, bármikor felügyelhető a kiállított tanúsítványok ellenőrzése az adatfolyam használata során bármikor.

Azt is fontos hangsúlyozni, a remote access szolgáltatás, bár lényeges eleme a Safebox platformnak, hiánya nem akadályozza meg a szoftver működését, csupán a távoli elérés lehetőségét vonja meg a felhasználóktól. Ez azt jelenti, hogy a Safebox platformot használók továbbra is hozzáférhetnek adataikhoz és szolgáltatásaikhoz helyi hálózaton keresztül, vagy akár közvetlenül a Safebox eszközükön, anélkül, hogy a remote access funkciót használnák. A szolgáltatás tervezetten díjfizetés köteles elem, amely egyébként nem csak a távoli elérést, de a domainek, aldomainek kezelését, regisztrációját, törlését, mobil applikációk használatát is magában foglalja. Továbbá más olyan szolgáltatásokat is tartalmaz, mint forgalmi adatok megjelenítése, statisztikák, stb. Ezen szolgáltatások használata opcionális, a Safebox platform alapvető funkciói a remote access szolgáltatás nélkül is teljes mértékben használhatók, ugyanakkor ma nem létezik olyan szolgáltató, amely nem kérne díjat a domainek kezeléséért, a publikus elérések biztosításáért, így a Safebox platform esetében is ez egy olyan szolgáltatás, amelynek használata díjfizetéshez kötött.
</p>

### Multiple georeduntant backups

<p align="justify">
Az adatmentés és helyreállítás lehetősége kritikus fontosságú a személyes adatok és szolgáltatások biztonsága szempontjából. A Safebox alap esetben tartalmazza a támogatott 3rd party alkalmazásokban keletkezett adatok mentési lehetőségeit, szolgáltatások szerint kijelölheő módon, melyek az érintett szolgáltatások, azokhoz mennyi mentendő adat párosul, illetve jelenleg milyen állapotban van azok mentése, a legtöbb jellegzetes metaadat tárolása mellett. Ez a szolgáltatás lehetővé teszi, hogy a felhasználó, helyi hálózatában más Safebox platformot futtató gépeire is mentse adatait, automatizált, ütemezett módokon - mindezt bármilyen 3rd party szolgáltató bevonása nélkül. A helyreállítás lehetősége is adott a felületen, ahol a felhasználó a forrás és a visszaállítási pont kiválasztása után, egyetlen kattintással visszaállíthatja adatait. Fontos hangsúlyozni, a Safebox platform csak a lehetőséget biztosítja, a mentési helyek kialakítása (tehát további Safebox platformot futtató eszközök felállítása, működtetése, hálózati beállításai), azok elérhetősége, kapacitása, stb. a felhasználó felelőssége.

A szolgáltatás specifikus adatmentés és helyreállítási lehetőségek mellett a Safebox platform lehetőséget biztosít arra is, hogy a felhasználó ne csak a helyi hálózatában tudjon mentési és helyreállítási végpontokat felhasználni, hanem geológiailag elkülönített környezetekben is kialakíthasson ilyen végpontokat. Ezek kialakításának felelőssége, az előbb bemutatott helyi mentési végpontok kialakításához hasonlóan, a felhasználóé. Ugyanakkor arra is lehetőséget ad, hogy a felhasználó, más Safebox felhasználóval együttműködjön és más Safebox felhasználó gépére helyezzen el mentési állományokat, természetesen a tömörítés mellett, teljes adattitkosítás használata mellett. Természetesen ekkor adatai valóban más, a felhasználó által már nem ellenőrizhető módon kerülnek tárolásra, ugyannakkor azokat ő távolról megsemmísitheti, és az alapértelmezett adattitkosítás miatt azokhoz a mentési állományokhoz csak ő fér hozzá és mivel ez a mód alapvetően interperszonális kapcsolatokhoz kötött, a felhasználó döntése, ki az a személy, akiben megbízik.

Ez az adatmentési és helyreállítási rendszer kereszt szolgáltatós módon is működik, tehát a Safebox platformot használó felhasználók egymás között is megoszthatják mentési végpontjaikat, természetesen a megfelelő biztonsági intézkedések betartása mellett. Ez a rendszer lehetővé teszi, hogy a felhasználók kihasználják a közösség erejét az adatok biztonságos tárolására és helyreállítására, miközben megőrzik adataik feletti ellenőrzést és biztonságát.
</p>

### 3rd party service management via templates

### Integrated domain management


# What is the differencies between any existing solutions and our approach?

## Why is it better?

## Who is this for?

# Technical Architecture

## Concepts and Definitions

## Core Components

## Implementation Details

## System Requirements

## Security Considerations

# Template Use Cases

# Future Work

# Conclusion