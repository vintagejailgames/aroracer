Program ARacer;

{$A+,B-,G+,E+,I+,N+,X+}

uses
	crt, DKeyb, Dgraf, GIFLoad;

const
  NUMTILES = 255;
  FITXER_PALETA   = 'paleta.pal';
  FITXER_PISTA    = 'track1.raw';
  FITXER_SPRITES  = 'sprites.raw';
  FITXER_TILES    = 'tiles.raw';
  FITXER_PRECALC  = 'arxiu.txt';


{$DEFINE DEBUG}

type
	Pmapa = ^MapaArray;
	MapaArray = array[0..254, 0..255] of byte;
	PTiles = ^ArrayTiles;
	ArrayTiles = array[0..127{254}, 0..NUMTILES] of byte;
	PliniesP = ^LiniesP;
	LiniesP = array[0..32760] of integer;

const
	LINIES = 90; {quantes linies pintem}
	FOV = 21780; {definim el fov (field of view)}

var
	map                     : Pmapa;
  tiles                   : PTiles;
	LineTable               : array[1..3] of PliniesP;
	xpos, ypos, angle       : word;
  SpeedLimit              : byte;
  speed, gir, Accel       : single;
  bots                    : byte;
	CoordPtr                : array[0..255] of pointer;
	SinusTable              : array[0..639] of integer;
  WorkPage                : PtrVScreen;
  WP                      : word;
  SpritesPage             : PtrVScreen;
  SP                      : word;
  mapa                    : boolean;
  LA_Z                    : array[1..90] of integer;
  mem_avail,max_avail     : longint;


(*------------------------------------------------*)




{ ********************************************************************************************}
{ PRECALCULA ELS SINUS }
{ ********************************************************************************************}
procedure InitSinus;
var
	i : integer;
	v, vadd : real;
begin
	v:=0.0;
	vadd:=(2.0*pi/512.0);
	for i:=0 to 639 do begin
		SinusTable[i]:=round(sin(v)*32767);
		v:=v+vadd;
	end;
end;


{ ********************************************************************************************}
{ PRECALCULA LES X PROJECTADES }
{ ********************************************************************************************}
procedure InitXProj;
var
  f       : file of integer;
  i       : byte;
begin
assign(f, FITXER_PRECALC);
reset(f);
for i := 1 to 90 do
  begin
  read(f,LA_Z[i]);
  end;
close(f);
end;



{ ********************************************************************************************}
{ FICA LA PALETA }
{ ********************************************************************************************}
procedure CarregaPaleta;
var
  pal        : auxpalette;
begin
LoadPalette(FITXER_PALETA, pal);
SetPalette(pal);
end;







{ ********************************************************************************************}
{ CARREGA EL MAPA }
{ ********************************************************************************************}
procedure CarregaMapa;
begin
GetMem(map,65535);
FillChar(map^,65535,#0);
LoadImage(FITXER_PISTA, map, 65280);
map^[100,200] := 1;
end;






{ ********************************************************************************************}
{ CARREGA ELS TILES }
{ ********************************************************************************************}
procedure CarregaTiles;
begin
	GetMem(tiles,32768{65535});
  LoadImage(FITXER_TILES,tiles,32768{65280});
end;






{ ********************************************************************************************}
{ PINTA ELS TILES }
{ ********************************************************************************************}
procedure PintaTile(num : integer);
var
  i,j: word;
begin
for i := 0 to 254 do
  for j := 0 to NUMTILES do
    putpixel(i+((j shr 7)shl 5), j and 127, tiles^[i,j],WP);
end;






{ ********************************************************************************************}
{ PRECALCULA LES LINIES }
{ ********************************************************************************************}
procedure PrecalcLinies;
const
	XPOS = 40; {altura del cotxe}
var
	q,p,i, x1,y1,x2,y2 : integer;
	z,sin1,cos1 : integer;
	pos,angle : word;
	cx,cy : longint;
  f : file of integer;
{  si  : boolean;}
begin
	for i:=1 to 3 do GetMem(LineTable[i],65535);
{  si := true;}
	p:=1;
	pos:=0;
	angle:=0;
	for q:=0 to 255 do begin
		CoordPtr[q]:=@LineTable[p]^[pos];

		z:=2100;
		sin1:=SinusTable[angle];
		cos1:=SinusTable[angle+128];
{    if si then
      begin
      assign(f,'arxiu.txt');
      rewrite(f);
      end;}
		for i:=1 to LINIES do begin
			x1:=LongDiv(-XPOS*65536,z); {calcular la primera coord}
			y1:=LongDiv((LINIES-i)*longint(FOV),z);
{      if si then write(f,y1);}
			cx := (LongMul(x1,cos1) - LongMul(y1,sin1)) DIV 32768; {rotar-la}
			cy := (LongMul(x1,sin1) + LongMul(y1,cos1)) DIV 32768;

			x1:=cx;
			y1:=cy;
			LineTable[p]^[pos]:=x1;
			LineTable[p]^[pos+1]:=y1;

			x2:=LongDiv(XPOS*65535,z); {calcular la segona coord}
			y2:=LongDiv((LINIES-i)*longint(FOV),z);
			cx := (LongMul(x2,cos1) - LongMul(y2,sin1)) DIV 32768; {rotar-la}
			cy := (LongMul(x2,sin1) + LongMul(y2,cos1)) DIV 32768;
			x2:=cx;
			y2:=cy;
			LineTable[p]^[pos+2]:=(longint(x2-x1) SHL 11) DIV 160;
			LineTable[p]^[pos+3]:=(longint(y2-y1) SHL 11) DIV 160;
			inc(pos,4);

			inc(z,310);
		end;
{    if si then begin close(f); si := false; end;}
		{Mirar si el proxim grup de coordenades hi ha que ficar-lo en altre buffer, ja que
		 no caben totes en un segment de 64Kb !!!}
		if ((pos*2 + (LINIES*8)) > 65200) then begin
			inc(p);
			pos:=0;
		end;
		inc(angle,1); {calcular el pròxim angle}
	end;
end;




{ ********************************************************************************************}
{ INICIALITZACIONS VARIES }
{ ********************************************************************************************}
procedure InitAll;
var
	i : integer;
begin
  Cls(0,VGA);
	CarregaPaleta;
	InitSinus;
  InitXProj;
  InitVirtual(WorkPage,  WP);
  InitVirtual(SpritesPage, SP);
  LoadImage(FITXER_SPRITES,SpritesPage , 64000);



	CarregaMapa;
	CarregaTiles;
	PrecalcLinies;

	xpos:=5280; ypos:=3200;
	angle:=0;
  mapa := false;
  SpeedLimit := 16;
  Accel := 0.2;
  bots := 0;
end;



{ ********************************************************************************************}
{ ALLIBERA MEMORIA }
{ ********************************************************************************************}
procedure EndAll;
var
	i : integer;
begin
  EndVirtual(WorkPage);
  EndVirtual(SpritesPage);
	FreeMem(map,65535);
	FreeMem(tiles,65535);
	for i:=1 to 3 do FreeMem(LineTable[i],65535);
end;


(*------------------------------------------------*)




{ ********************************************************************************************}
{ RUTINA DE MOVIMENT DEL COTXE }
{ ********************************************************************************************}

procedure MouKart;
var
	x,y, sin1,cos1 : integer;
	cx,cy : longint;
begin
	{Trobar el nou angle de rotació}
	If (keypress(KeyArrowLeft)) and ((speed > 1) or (speed < -1)) then
    begin
    gir := 2;
    {If gir < 4 then gir := gir + 0.4;}
    end
  else
  	If (keypress(KeyArrowRight)) and ((speed > 1) or (speed < -1)) then
      begin
      gir := -2;
      {If gir > -4 then gir := gir - 0.4;}
      end
    else If gir > 0 then gir := gir - 0.4 else gir := gir + 0.4;

  x := trunc(gir);
	angle:=(angle + x) AND 511;

	{estem movent-se cap avant?}
	if (keypress(KeyArrowUp)) then
    begin
    if speed <= SpeedLimit then speed := speed + Accel;
    if speed > SpeedLimit then speed := speed - Accel;
    end
  else
    if (keypress(KeyArrowDown)) then
      begin
      if speed >= -8 then speed := speed - Accel;
      end
    else
      if speed > 0 then speed := speed - Accel else speed := speed + Accel;

	if (speed <> 0) then
    begin
    If map^[ypos div 32, xpos div 32] = 0 then SpeedLimit := 8 else SpeedLimit := 16-trunc(abs(gir));
{    If map^[ypos div 32, xpos div 32] = 3 then Speed := -Speed;}
		sin1:=SinusTable[angle];
		cos1:=SinusTable[angle+128];
		x:=0;  {velocitat de moviment}
		y:=trunc(speed);
		cx := (longmul(x,cos1) - longmul(y,sin1)) DIV 32768;
		cy := (longmul(x,sin1) + longmul(y,cos1)) DIV 32768;
		inc(xpos,cx);
		inc(ypos,cy);
    end;

	{no ens en podem eixir del mapa}
	if (xpos<200) then xpos:=200;
	if (xpos>7850) then xpos:=7850{16384};
	if (ypos<200) then ypos:=200;
	if (ypos>7850) then ypos:=7850;
end;

(*------------------------------------------------*)


{ BUSQUEM LA X ON PINTAR EL COTXE }
Function Xproj(X : integer): byte;
var
  index     : byte;
  trobat    : boolean;
  ant, act  : word;
begin
index := 1;
trobat := False;
ant := LA_Z[index];
repeat
  act := LA_Z[index];
  if X < act then
    begin
    ant := act;
    inc(index);
    end
  else
    if X > act then
      begin
      If X-act < ant-X then ant := act;
      act := ant;
      trobat := True;
      end
    else
      trobat := True;
until trobat;
Xproj := index;
{ 'index' és el que busquem }
end;






{ ********************************************************************************************}
{ RUTINA DE PINTAT DE LA VELOCITAT }
{ ********************************************************************************************}
Procedure PintaVel;
var
  temp  : byte;
begin
temp := trunc(speed/0.2);
if temp <> 0 then temp := temp + 1;
PutSprite(SP,32000+((temp div 10)*20),WP,0,10,20,17);
PutSprite(SP,32000+((temp mod 10)*20),WP,15,10,20,17);
PutSprite(SP,37440,WP,32,20,19,9);

{temp := trunc(xpos shr 5);
PutSprite(SP,32000+((temp div 100)*20),WP,0 ,30,20,17);
PutSprite(SP,32000+(((temp mod 100) div 10)*20),WP,15,30,20,17);
PutSprite(SP,32000+((temp mod 10 )*20),WP,30,30,20,17);

temp := trunc(ypos shr 5);
PutSprite(SP,32000+((temp div 100)*20),WP,         45,30,20,17);
PutSprite(SP,32000+(((temp mod 100) div 10)*20),WP,60,30,20,17);
PutSprite(SP,32000+((temp mod 10 )*20),WP,         75,30,20,17);}

end;




{ ********************************************************************************************}
{ RUTINA DE PINTAT DEL MAPA }
{ ********************************************************************************************}
Procedure DrawMapa;
var
  i,j   : byte;
begin
  i := 0; j := 0;
  repeat
    j := 0;
    repeat
    If map^[i,j] = 1 then PutPixel(240+(i div 3),(j div 3)-10,0,WP);
    j := j + 3;
    until j >= 255;
  i := i + 3;
  until i >= 254;
  PutSprite(SP, 37779, WP, 238+((ypos) div 96), ((xpos) div 96)-13, 6, 6);
{  PutPixel(201+((ypos) div 96), (xpos) div 96, 5, WP);}
end;



{ ********************************************************************************************}
{ RUTINA DE PINTAT DEL FONDO }
{ ********************************************************************************************}

Procedure DrawFondo(mov : word);
begin
If mov = 0 then
  begin
  PutBlocR(SP, 54400, WP, 0, 0, 320, 10);
  exit;
  end;
If mov = 320 then
  begin
  PutBlocR(SP, 57600, WP, 0, 0, 320, 10);
  exit;
  end;
If mov < 320 then
  begin
  PutBlocR(SP, 54400+mov, WP, 0      , 0, 320-mov, 10);
  PutBlocR(SP, 57600    , WP, 320-mov, 0, mov    , 10);
  exit;
  end;
If mov > 320 then
  begin
  PutBlocR(SP, 57280+mov, WP, 0      , 0, 640-mov, 10);
  PutBlocR(SP, 54400    , WP, 640-mov, 0, mov-320, 10);
  exit;
  end;
end;



{ ********************************************************************************************}
{ RUTINA DE PINTAT DEL FONDO2 }
{ ********************************************************************************************}

Procedure DrawFondo2(mov : word);
begin
mov := (mov shr 1) mod 320;
If mov = 0
  then PutSprite(SP, 60800, WP, 0, 0, 320, 10)
else
  begin
  PutSprite(SP, 60800+mov, WP, 0      , 0, 320-mov, 10);
  PutSprite(SP, 60800    , WP, 320-mov, 0, mov    , 10);
  end;
end;




{ ********************************************************************************************}
{ RUTINA DE PINTAT DE LA PISTA }
{ ********************************************************************************************}

procedure PintaPista(x,y, angle : integer; Coords : pointer); assembler;
var
	mappos,tablepos : word;
	xadd,yadd,
	mapxadd,mapyadd : integer;
	height, counts : word;
asm
	push	ds
	mov	es,WP
	mov	di,10*320
	mov	ax,WORD PTR [map+2]
	{mov fs,ax} DB $8E,$E0
	mov	ax,WORD PTR [Coords+2]
	{mov gs,ax} DB $8E,$E8
	mov	ax,WORD PTR [Coords]
	mov	[tablepos],ax
	mov	ds,WORD PTR [tiles+2]

	cld
	mov	[height],LINIES
@y_run:

	mov	si,[tablepos]

	DB $65; mov	ax,[si+4]
	cmp	[angle],256
	jb		@anglebaix1
	neg	ax
@anglebaix1:
	mov	[xadd],ax
	mov	[mapxadd],1
	or		ax,ax
	jns	@mapaxalt
	mov	[mapxadd],-1
@mapaxalt:

	DB $65; mov	ax,[si+6]
	cmp	[angle],256
	jb		@anglebaix2
	neg	ax
@anglebaix2:
	mov	[yadd],ax
	mov	[mapyadd],256
	or		ax,ax
	jns	@mapayalt
	mov	[mapyadd],-256
@mapayalt:

	DB $65; mov	dx,[si]
	DB $65; mov	cx,[si+2]
	cmp	[angle],256
	jb		@anglebaix3
	neg	cx
	neg	dx
@anglebaix3:
	add	dx,[x]
	add	cx,[y]

	mov	bx,dx					{Troba el primer tile}
	mov	ax,cx
	shr	ax,5
	shr	bx,5
	mov	bh,al
	mov	[mappos],bx
	DB $64; mov al,[bx]		{Pilla el index del tile del mapa}
	mov	ah,al					{Troba la posició del mapa en el buffer de mapa}
	and	al,7
	shr	ah,3
	shl	ax,5
	mov	si,ax

	shl	dx,11
	shl	cx,11
	xor	dx,$8000
	xor	cx,$8000

	mov	[counts],160
@x_run:
	mov	bh,dh		{Pilla la x del pixel}
	mov	bl,ch		{Pilla la y del pixel}
	shr	bx,3
	and	bx,$1F1F
	mov	al,[si+bx]	{Pilla eixe pixel}
	mov	ah,al
	stosw					{guardem-lo... estem dibuixant-lo dos vegades??}

	add	dx,[xadd]			{anyadir a la inclinació de x}
	jno	@noxadd
	mov	bx,[mappos]
	add	bx,[mapxadd]
	mov	[mappos],bx
	DB $64; mov al,[bx]		{Pilla el index del tile del mapa}
	mov	ah,al					{Troba la posició del mapa en el buffer de mapa}
	and	al,7
	shr	ah,3
	shl	ax,5
	mov	si,ax
@noxadd:

	add	cx,[yadd]			{anyadir a la inclinació de y}
	jno	@noyadd
	mov	bx,[mappos]
	add	bx,[mapyadd]
	mov	[mappos],bx
	DB $64; mov al,[bx]		{Pilla el index del tile del mapa}
	mov	ah,al					{Troba la posició del mapa en el buffer de mapa}
	and	al,7
	shr	ah,3
	shl	ax,5
	mov	si,ax
@noyadd:

	dec	[counts]
	jnz	@x_run

	add	[tablepos],8
	dec	[height]
	jnz	@y_run

	pop	ds
end;


(*------------------------------------------------*)



{ ********************************************************************************************}
{ BUCLE PRINCIPAL }
{ ********************************************************************************************}
procedure Bucle;
var
  enx, eny, equis  : integer;
  temp      : byte;
begin
MouKart;

DrawFondo(trunc((512-angle)*1.25));
DrawFondo2(trunc((512-angle)*1.25));
PintaPista(xpos,ypos, angle, CoordPtr[angle AND 255]);

if bots = 1 then bots := 0 else bots := 1;

If (gir > -1) and (gir < 1) then PutSprite(SP,0,WP,144,40+(((xpos+ypos)and 7) shr 2),32,32);
If gir <=-1 then PutSprite(SP,32,WP,144,40+(((xpos+ypos)and 7) shr 2),32,32);
If gir >= 1 then PutSprite(SP,64,WP,144,40+(((xpos+ypos)and 7) shr 2),32,32);


{ CALCUL DE LA POSICIÓ D'UN ENEMIC }
enx := (LongMul(5216-xpos,SinusTable[angle+128]) + LongMul(3264-ypos,SinusTable[angle]))     DIV 32768;
eny := (LongMul(5216-xpos,SinusTable[angle])     - LongMul(3264-ypos,SinusTable[angle+128])) DIV 32768;
eny := -eny;
If (eny > 0) then
  begin
  If eny <= 928 then
    begin
    equis := 157+Trunc((((1.875/89)*Xproj(eny))+0.125)*enx)-trunc(((930-eny)/928)*16);
    If (equis >= 0) and (equis <= 287) then
      Scale2DMaskedClipped(SP,WP,32,32,equis,7+Xproj(eny)-trunc(((930-eny)/928)*30),(930-eny)/928);
    end;
  end;
{ FINAL DEL CALCUL DE LA POSICIÓ D'UN ENEMIC }


PintaVel;
DrawMapa;
{DEBUG}If keypress(keyT) then PintaTile(0);
{DEBUG}if keypress(keyC) then cls(0,VGA);

WaitRetrace; {SplitScreen(1,WP,VGA);SplitScreen(0,WP,VGA);}
Flip(WP,VGA);
{DEBUG}mem_avail := memavail;
{DEBUG}max_avail := maxavail;
end;





{ ********************************************************************************************}
{ PROGRAMA PRINCIPAL }
{ ********************************************************************************************}
begin
  speed := 0;
  gir := 0;
	InitGraph;
	InitAll;
  InitKb;
	repeat Bucle until KeyPress(KeyESC);
  EndKb;
	EndAll;
	EndGraph;
{  clrscr;
  writeln('MAXAVAIL = ',max_avail);
  writeln('MEMAVAIL = ',mem_avail);}
end.
