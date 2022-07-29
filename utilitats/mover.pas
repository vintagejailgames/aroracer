program mover;

uses crt, dgraf;

type
  Bloc    = array[1..64000] of byte;
  PtrBloc = ^Bloc;
var
  pal, auxpal : AuxPalette;
  i,j,c       : word;
  temp        : PtrBloc;
begin
c := 0;
clrscr;

Write('Agafant paleta dels tiles...');
LoadPalette('tiles.pal',auxpal);
For i := 0 to 63 do
  begin
  pal[c].R := auxpal[i].R;
  pal[c].G := auxpal[i].G;
  pal[c].B := auxpal[i].B;
  inc(c);
  end;
Writeln('OK');

{Write('Agafant paleta del fondo...');
LoadPalette('fondo.pal',auxpal);
For i := 0 to 63 do
  begin
  pal[c].R := auxpal[i].R;
  pal[c].G := auxpal[i].G;
  pal[c].B := auxpal[i].B;
  inc(c);
  end;
Writeln('OK');}

Write('Agafant paleta dels sprites...');
LoadPalette('sprites.pal',auxpal);
For i := 0 to 79 do
  begin
  pal[c].R := auxpal[i].R;
  pal[c].G := auxpal[i].G;
  pal[c].B := auxpal[i].B;
  inc(c);
  end;
Writeln('OK');

Write('Guardant paleta nova...');
SavePalette('paleta.pal',pal);
Writeln('OK');

Getmem(temp, 65535);

{Write('Canviant indexos en fondo.raw...');
LoadImage('fondo1.raw',temp,64000);
For i := 1 to 64000 do temp^[i] := temp^[i] + 64;
SaveImage('fondo.raw',temp,64000);
Writeln('OK');}

Write('Canviant indexos en sprites.raw...');
LoadImage('sprites1.raw',temp,64000);
For i := 1 to 64000 do if temp^[i] <> 0 then temp^[i] := temp^[i] + 64;
SaveImage('sprites.raw',temp,64000);
Writeln('OK');

Freemem(temp, 65535);

Writeln('Treball acavat satisfactoriament.');
repeat until keypressed;
end.