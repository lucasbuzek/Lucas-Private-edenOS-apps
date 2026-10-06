EDEN / edenOS CORE — KONSOLIDOVANÁ ZÁLOHA NÁVRHU A REFERENCIÍ
Verzia: 0.1
Dátum: 2026-09-22
Vlastník: Lucas Buzek
EDEN: Engineering, Development, Exploration & Nature

ÚČEL
Balík konsoliduje obnovenú architektúru gardenOS → edenOS Core → ekosystém strojov, pravidlá pre NANDI a samostatné línie strojov, aktuálne HW požiadavky a register externých open-source/produktových referencií. Slúži ako pracovná architektúra aj ako obnoviteľná záloha.

KANONICKÁ LÍNIA
gardenOS Core je overený technický predchodca/testovacia základňa.
Všeobecné schopnosti sa postupne extrahujú a zovšeobecňujú do edenOS Core.
edenOS Core je spoločná architektúra/runtime.
gardenOS zostáva poľnohospodárskou/environmentálnou doménovou aplikáciou.
NANDI zostáva malou univerzálnou pomocnou líniou pre viac domén.
Špecializované stroje (napr. Mechanical Mule) majú vlastné línie, ale používajú rovnakú architektúru edenOS Core.

HLAVNÉ PRAVIDLO
NAJPRV IMPLEMENTOVAŤ / INTEGROVAŤ EXISTUJÚCU SCHOPNOSŤ, AŽ POTOM JU ZNOVU VYTVÁRAŤ.
Pred pridaním funkcie do edenOS Core najprv skontrolovať gardenOS a externý register referencií.

Externé projekty sú referencie/kandidáti na integráciu, nie automatické závislosti. Pred kopírovaním kódu, PCB, CAD alebo dokumentácie je nutná kontrola presnej licencie a pôvodu.
