# Arounders Racer

<sup>0.62 ALPHA 9 AVORRIMENT RELEASE</sup>

![aroracer](https://user-images.githubusercontent.com/110221325/181750926-c0f8c378-7e92-4ba9-bdff-fea8bffbe3c6.png)

## Descripció

Proves de joc de carreres tipo Super Mario Kart de la SNES. Nomes es un test.

## Sobre la versió

Aquesta és una versió MOLT retallada i encara no lo suficient maura del joc final. La major
part de les coses podrien canviar en la versió final.

Els grafics són preliminars. Els Karts han sigut rippetjats del SuperMario Kart de SNES, i no
són ni molt menys els que s'usaràn en el joc final, són nomes per a proves.

Per tot açò, aquesta demo només es pot considerar com una mostra del motor gràfic utilitzat
en el joc.

[Afegit el 26-03-01]
El codi font està inclos, així com les utilitats creades per a l'ocasió.
Dubte que acave mai este joc.

## Instruccions

 * `Cursors` Mouret per la pantalla
 * `ESC` Eixir

## Tips

* Recorda que has de accelerar o fer marxa enrera per a que gire el kart.
* Mira el mapa per a no perdret, la pista inclosa en aquesta demo és molt xicoteta comparada
  amb lo gran que podria ser.
* Per la gespa el kart va mes lento, recorda-ho
* Al girar, per poc que siga, també perds velocitat

## Known bugs

* Al fer marxa enrera, la velocitat eix un pixel massa cap amunt (tinc que fer un ABS, o algo)
* El senyalitzador del mapa se'n va de la pantalla i fa paranoies, encara no m'he preocupat
  per ell
* El enemic sempre es veu de darrere, el mires per on el mires, les rotacions no han sigut
  implementades.
* El sprite de l'enemic sempre esta davant del teu. Z-order encara no implementat

## Com jugar hui en dia

En DosBox funciona, pero hi ha que pujar prou els cicles. Al voltat de 50000 pareixia anar prou be. Prova a vore.

## Compilar hui en dia

Usant Turbo Pascal 7 des de DosBox. Atenció, no vaig aconseguir que funcionara des de l'IDE, pega petardà per quedar-se sense memòria. Has de compilar el EXE i executar-lo des de fora de Turbo Pascal.

Com sempre, recorda activar "Options -> Compiler -> 286 Instructions".

```
jaildoctor@gmail.com
JailDoctor© 2000
```
