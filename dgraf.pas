unit dgraf;

interface

type
  RGB = record
    R,G,B: byte;
  end;

  AuxPalette = array [0..255] of RGB;

  VScreen = array [1..64000] of byte;
  PtrVScreen = ^VScreen;

const
  VGA = $a000;


  Procedure InitGraph;

  Procedure EndGraph;

  Procedure WaitRetrace;

  Procedure InitVirtual(var screen: PtrVScreen; var address:word);

  procedure EndVirtual(var screen: PtrVScreen);

  Procedure Flip(orig,dest: word);

  Procedure SplitScreen(num, orig, dest: word);

  Procedure Cls(color: byte; address: word);

  Procedure GetRGB(index: byte; var r,g,b: byte);

  Procedure SetRGB(index: byte; r,g,b: byte);

  Procedure GetPalette(var palette: AuxPalette);

  Procedure SetPalette(palette: AuxPalette);

  Procedure LoadPalette(filename:string; var pal: AuxPalette);

  Procedure SavePalette(filename:string; var pal: AuxPalette);

  procedure PartPal(p1,p2: byte; palette: AuxPalette);

  Procedure FadeIn(palette: AuxPalette);

  Procedure FadeOut;

  Procedure FadeToCol(r,g,b:byte);

  Function FadeInStep(palette: AuxPalette): boolean;

  Function FadeOutStep: boolean;

  Function FadeToColStep(r,g,b:byte): boolean;

  Procedure Blackout;

  Procedure PutPixel(x,y: word; color: byte; address: word);

  Function GetPixel(address: word; x,y: integer): byte;

  Procedure PutSprite(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word);

  Procedure Scale2DMaskedClipped(font,desti,ample,alt,posx,posy:word;zoom:real);

  procedure AlphaSprite(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word;alpha:byte);

  Procedure PutBloc(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word);

  Procedure PutBlocR(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word);

  Function LongDiv(x : longint; y : integer) : integer;
  inline($59/$58/$5A/$F7/$F9);
  Function LongMul(x, y : integer) : longint;
  inline($5A/$58/$F7/$EA);

  Procedure LoadImage(name: string; address: pointer; size: word);

  Procedure SaveImage(name: string; address: pointer; size: word);

implementation

{ ---------------------------------------------------------------------------------}

Procedure InitGraph; Assembler;
Asm
  Mov ax,$13
  Int 10h
End;

{ ---------------------------------------------------------------------------------}

Procedure EndGraph; Assembler;
Asm
  Mov   AX, 003H
  Int   010H
End;

{ ---------------------------------------------------------------------------------}

Procedure WaitRetrace; assembler;
label
  l1,l2;
Asm
  mov dx,3dah

  l1:
     in al,dx
     test al,8
     jne l1

  l2:
     in al,dx
     test al,8
     je l2
End;

{ ---------------------------------------------------------------------------------}

Procedure InitVirtual(var screen: PtrVScreen; var address:word);
begin
  getmem(screen,64000);
  address:= seg(screen^);
end;

{ ---------------------------------------------------------------------------------}

Procedure EndVirtual(var screen: PtrVScreen);
begin
  If screen <> nil then freemem(screen,64000);
end;

{ ---------------------------------------------------------------------------------}

Procedure Flip(orig,dest: word); assembler;
asm
  push ds
  mov ax,orig
  mov ds,ax
  xor di,di
  mov ax,dest
  mov es,ax
  xor si,si
  mov cx,16000
  db $66
  rep movsw
  pop ds
end;

{ ---------------------------------------------------------------------------------}

Procedure SplitScreen(num,orig,dest: word); assembler;
asm
  push ds

  mov ax,orig         { Fiquem l'orige en DS }
  mov ds,ax
  xor di,di           { Fiquem a 0 DI (part de baix per defecte) }
  mov ax,num          { Comprovem si num = 1  (1 -> dalt ; 0 -> baix) }
  cmp ax,1
  jnz @dalt           { si es 1 botem a @dalt }
  jmp @cont           { sino (si es 0) botem a @cont, o siga, continuem }

@dalt:
  mov di, 32000       { Fiquem DI a 32000 (part de dalt, 320*100) }

@cont:
  mov ax,dest         { Fiquem el desti en ES }
  mov es,ax
  xor si,si           { Fiquem a 0 SI }

  mov cx,100          { Anem a pintar 100 linies (la meitat de la pantalla) }

@linia:
  push cx             { guardem-ho, ara despres ho tornem a pillar }
  push si

  mov cx,80           { Pintem tota una linia (320 pixels / 4 (dwords) = 80) }
  db $66
  rep movsw

  pop si
  add si,640
  pop cx              { Recuperem les linies }
  dec cx              { una menos pa pintar }
  cmp cx, 0           { queden linies? }
  jnz @linia          { si, tornem a pintar }

  pop ds              { no, acavem }
end;

{ ---------------------------------------------------------------------------------}

Procedure Cls(color: byte; address: word); assembler;
Asm
  mov ax,address
  mov es,ax
  xor di,di
  mov al,color
  mov ah,al
  mov cx,16000
  db $66
  rep stosw
End;

{ ---------------------------------------------------------------------------------}

Procedure GetRGB(index: byte; var r,g,b: byte);
begin
  port[$3c7]:= index;
  r:= port[$3c9];
  g:= port[$3c9];
  b:= port[$3c9];
end;

{ ---------------------------------------------------------------------------------}

Procedure SetRGB(index: byte; r,g,b: byte);
begin
  port[$3c8]:= index;
  port[$3c9]:= r;
  port[$3c9]:= g;
  port[$3c9]:= b;
end;

{ ---------------------------------------------------------------------------------}

Procedure GetPalette(var palette: AuxPalette);
var
  loop: byte;
begin
  for loop:= 0 to 255 do
    GetRGB(loop,palette[loop].r,palette[loop].g,palette[loop].b);
end;

{ ---------------------------------------------------------------------------------}

Procedure SetPalette(palette: AuxPalette);
var
  loop: byte;
begin
  WaitRetrace;
  for loop:= 0 to 255 do
    SetRGB(loop,palette[loop].r,palette[loop].g,palette[loop].b);
end;

{ ---------------------------------------------------------------------------------}

Procedure LoadPalette(filename:string; var pal: AuxPalette);
var
  f : file of AuxPalette;
begin
  Assign(f,filename);
  Reset(f);
  Read(f,Pal);
  Close(f);
end;

{ ---------------------------------------------------------------------------------}

Procedure SavePalette(filename:string; var pal: AuxPalette);
var
  f : file of AuxPalette;
begin
  Assign(f,filename);
  Rewrite(f);
  Write(f,Pal);
  Close(f);
end;

{ ---------------------------------------------------------------------------------}

procedure PartPal(p1,p2: byte; palette: AuxPalette);
var
  loop: byte;
begin
  WaitRetrace;
  for loop:= p1 to p2 do
    SetRGB(loop,palette[loop].r,palette[loop].g,palette[loop].b);
end;

{ ---------------------------------------------------------------------------------}

Procedure FadeIn(palette: AuxPalette);
var
  loop1,loop2: byte;
  aux: array [1..3] of byte;
begin
  for loop1:= 1 to 64 do
    begin
    WaitRetrace;
    for loop2:= 0 to 255 do
      begin
      GetRGB(loop2,aux[1],aux[2],aux[3]);
      if (aux[1] < palette[loop2].r) then inc(aux[1]);
      if (aux[2] < palette[loop2].g) then inc(aux[2]);
      if (aux[3] < palette[loop2].b) then inc(aux[3]);
      SetRGB(loop2,aux[1],aux[2],aux[3]);
      end;
    end;
end;

{ ---------------------------------------------------------------------------------}

Procedure FadeOut;
var
  loop1,loop2: byte;
  aux: array [1..3] of byte;
begin
  for loop1:= 1 to 64 do
    begin
    WaitRetrace;
    for loop2:= 0 to 255 do
      begin
      GetRGB(loop2,aux[1],aux[2],aux[3]);
      if (aux[1] > 0) then dec(aux[1]);
      if (aux[2] > 0) then dec(aux[2]);
      if (aux[3] > 0) then dec (aux[3]);
      SetRGB(loop2,aux[1],aux[2],aux[3]);
      end;
    end;
end;

{ ---------------------------------------------------------------------------------}

Procedure FadeToCol(r,g,b:byte);
var
  loop1,loop2: byte;
  aux: array [1..3] of byte;
begin
  for loop1:= 1 to 64 do
    begin
    WaitRetrace;
    for loop2:= 0 to 255 do
      begin
      GetRGB(loop2,aux[1],aux[2],aux[3]);
      if (aux[1] > r) then dec(aux[1]) else if aux[1] < r then inc(aux[1]);
      if (aux[2] > g) then dec(aux[2]) else if aux[2] < g then inc(aux[2]);
      if (aux[3] > b) then dec(aux[3]) else if aux[3] < b then inc(aux[3]);
      SetRGB(loop2,aux[1],aux[2],aux[3]);
      end;
    end;
end;

{ ---------------------------------------------------------------------------------}

Function FadeInStep(palette: AuxPalette): boolean;
var
  loop2: byte;
  aux: array [1..3] of byte;
begin
  FadeInStep := False;
  WaitRetrace;
  for loop2:= 0 to 255 do
    begin
    GetRGB(loop2,aux[1],aux[2],aux[3]);
    if (aux[1] < palette[loop2].r) then begin inc(aux[1]); FadeInStep := True; end;
    if (aux[2] < palette[loop2].g) then begin inc(aux[2]); FadeInStep := True; end;
    if (aux[3] < palette[loop2].b) then begin inc(aux[3]); FadeInStep := True; end;
    SetRGB(loop2,aux[1],aux[2],aux[3]);
    end;
end;

{ ---------------------------------------------------------------------------------}

Function FadeOutStep: boolean;
var
  loop2: byte;
  aux: array [1..3] of byte;
begin
  FadeOutStep := False;
  WaitRetrace;
  for loop2:= 0 to 255 do
    begin
    GetRGB(loop2,aux[1],aux[2],aux[3]);
    if (aux[1] > 0) then begin dec(aux[1]); FadeOutStep := True; end;
    if (aux[2] > 0) then begin dec(aux[2]); FadeOutStep := True; end;
    if (aux[3] > 0) then begin dec(aux[3]); FadeOutStep := True; end;
    SetRGB(loop2,aux[1],aux[2],aux[3]);
    end;
end;

{ ---------------------------------------------------------------------------------}

Function FadeToColStep(r,g,b:byte): boolean;
var
  loop2: byte;
  aux: array [1..3] of byte;
begin
  FadeToColStep := False;
  WaitRetrace;
  for loop2:= 0 to 255 do
    begin
    GetRGB(loop2,aux[1],aux[2],aux[3]);
    if (aux[1] > r) then
      begin dec(aux[1]); FadeToColStep := True; end
    else if aux[1] < r then
      begin inc(aux[1]); FadeToColStep := True; end;
    if (aux[2] > g) then
      begin dec(aux[2]); FadeToColStep := True; end
    else if aux[2] < g then
      begin inc(aux[2]); FadeToColStep := True; end;
    if (aux[3] > b) then
      begin dec(aux[3]); FadeToColStep := True; end
    else if aux[3] < b then
      begin inc(aux[3]); FadeToColStep := True; end;
    SetRGB(loop2,aux[1],aux[2],aux[3]);
    end;
end;

{ ---------------------------------------------------------------------------------}

Procedure Blackout;
var
  loop: integer;
begin
  WaitRetrace;
  for loop:= 0 to 255 do SetRGB(loop,0,0,0);
end;

{ ---------------------------------------------------------------------------------}

Procedure PutPixel(x,y: word; color: byte; address: word); Assembler;
Asm
  Mov   AX, address
  Mov   ES, AX
  Mov   DI, X
  Mov   BX, Y
  ShL   BX, 6
  Add   DI, BX
  ShL   BX, 2
  Add   DI, BX
  Mov   AL, Color
  STOSB
End;

{ ---------------------------------------------------------------------------------}

Function GetPixel(address: word; x,y: integer): byte; Assembler;
Asm
  Mov   AX, address
  Mov   ES, AX
  Mov   DI, X
  Mov   BX, Y
  ShL   BX, 6
  Add   DI, BX
  ShL   BX, 2
  Add   DI, BX
  Mov   AL, ES:[DI]
End;

{ ---------------------------------------------------------------------------------}

procedure PutSprite(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word);
   begin
    asm
       push ds;

       mov si,m_offset;

       mov ax,mem_orig;
       mov ds,ax;        {memoria orige}
       mov ax,mem_dest;
       mov es,ax;        {memoria desti}

       mov   di,posx;      {DI = X}
       mov   dx,posy;      {DX = Y}
       shl   dx,8;      {DX = 256*Y}
       add   di,dx;     {DI = 256*Y+BX}
       shr   dx,2;      {DX = 64*Y}
       add   di,dx;     {DI = 320*Y+X}

       mov cx,alt;     {guarde el alt}

   @1: push cx;        {guarde el alt}
       push di;        {guarde el offset desti}
       push si;        {guarde el offset orige}

       mov cx,ample;   {carregue el ample}

   @nou_pixel:
       mov al,ds:[si]       {color del pixel orige en al}
       or al,00h;           {AL=0?}
       jnz @paint;
       jmp @new;            {altre pixel}

   @paint:
       mov es:[di],al;      {pintar pixel}

   @new:
       inc di;              {augmentar punter pantalla}
       inc si;              {augmentar punter font}
       loop @nou_pixel;     {mentres no siga l'ample continuar}
       pop si;              {recuperem l'offset orige}
       pop di;              {recuperem l'offset desti}
       add si,320;          {segent linia orige}
       add di,320;          {segent linia desti}
       pop cx;              {recuperem l'alt}
       dec cx;              {una linia menys}
       cmp cx,0;            {Queden linies?}
       jnz @1;              {Si.Anar a @1}
       pop ds;
    end;
end;

{ ---------------------------------------------------------------------------------}

procedure AlphaSprite(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word;alpha:byte);
   begin
    asm
       push ds;

       mov si,m_offset;

       mov ax,mem_orig;
       mov ds,ax;        {memoria orige}
       mov ax,mem_dest;
       mov es,ax;        {memoria desti}

       mov   di,posx;      {DI = X}
       mov   dx,posy;      {DX = Y}
       shl   dx,8;      {DX = 256*Y}
       add   di,dx;     {DI = 256*Y+BX}
       shr   dx,2;      {DX = 64*Y}
       add   di,dx;     {DI = 320*Y+X}

       mov cx,alt;     {guarde el alt}

   @1: push cx;        {guarde el alt}
       push di;        {guarde el offset desti}
       push si;        {guarde el offset orige}

       mov cx,ample;   {carregue el ample}

   @nou_pixel:
       mov al,ds:[si]       {color del pixel orige en al}
       or al,00h;           {AL=0?}
       jnz @paint;
       jmp @new;            {altre pixel}

   @paint:
       mov al,es:[di];
       add al,alpha;
       mov es:[di],al;      {pintar pixel alpha}

   @new:
       inc di;              {augmentar punter pantalla}
       inc si;              {augmentar punter font}
       loop @nou_pixel;     {mentres no siga l'ample continuar}
       pop si;              {recuperem l'offset orige}
       pop di;              {recuperem l'offset desti}
       add si,320;          {segent linia orige}
       add di,320;          {segent linia desti}
       pop cx;              {recuperem l'alt}
       dec cx;              {una linia menys}
       cmp cx,0;            {Queden linies?}
       jnz @1;              {Si.Anar a @1}
       pop ds;
    end;
end;

{ ---------------------------------------------------------------------------------}

procedure PutBloc(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word);
begin
    asm
       push ds;

       mov si,m_offset;

       mov ax,mem_orig;
       mov ds,ax;        {memoria orige}
       mov ax,mem_dest;
       mov es,ax;        {memoria desti}

       mov   di,posx;      {DI = X}
       mov   dx,posy;      {DX = Y}
       shl   dx,8;      {DX = 256*Y}
       add   di,dx;     {DI = 256*Y+BX}
       shr   dx,2;      {DX = 64*Y}
       add   di,dx;     {DI = 320*Y+X}

       mov cx,alt;     {guarde el alt}

   @1: push cx;        {guarde el alt}
       push di;        {guarde el offset desti}
       push si;        {guarde el offset orige}

       mov cx,ample;   {carregue el ample}
       shr cx,2;

       db $66
       rep movsw;      {mentres no siga l'ample continuar}

       pop si;              {recuperem l'offset orige}
       pop di;              {recuperem l'offset desti}
       add si,320;          {segent linia orige}
       add di,320;          {segent linia desti}
       pop cx;              {recuperem l'alt}
       dec cx;              {una linia menys}
       cmp cx,0;            {Queden linies?}
       jnz @1;              {Si.Anar a @1}

     pop ds;
   end;
end;

{ ---------------------------------------------------------------------------------}

procedure PutBlocR(mem_orig,m_offset,mem_dest,posx,posy,ample,alt:word);
begin
    asm
       push ds;

       mov si,m_offset;

       mov ax,mem_orig;
       mov ds,ax;        {memoria orige}
       mov ax,mem_dest;
       mov es,ax;        {memoria desti}

       mov   di,posx;      {DI = X}
       mov   dx,posy;      {DX = Y}
       shl   dx,8;      {DX = 256*Y}
       add   di,dx;     {DI = 256*Y+BX}
       shr   dx,2;      {DX = 64*Y}
       add   di,dx;     {DI = 320*Y+X}

       mov cx,alt;     {guarde el alt}

   @1: push cx;        {guarde el alt}
       push di;        {guarde el offset desti}
       push si;        {guarde el offset orige}

       mov cx,ample;   {carregue el ample}
{       shr cx,2;

       db $66    }
       rep movsb;      {mentres no siga l'ample continuar}

       pop si;              {recuperem l'offset orige}
       pop di;              {recuperem l'offset desti}
       add si,320;          {segent linia orige}
       add di,320;          {segent linia desti}
       pop cx;              {recuperem l'alt}
       dec cx;              {una linia menys}
       cmp cx,0;            {Queden linies?}
       jnz @1;              {Si.Anar a @1}

     pop ds;
   end;
end;

{ ---------------------------------------------------------------------------------}

Procedure LoadImage(name: string; address: pointer; size: word);
var
  f   : file;
begin
  assign(f, name);
  reset(f,1);
  blockread(f,address^,size);
  close(f);
end;

{ ---------------------------------------------------------------------------------}

Procedure SaveImage(name: string; address: pointer; size: word);
var
  f   : file;
begin
  assign(f, name);
  rewrite(f,1);
  blockwrite(f,address^,size);
  close(f);
end;

{ ---------------------------------------------------------------------------------}

procedure Scale2DMaskedClipped(font,desti,ample,alt,posx,posy:word;zoom:real);
var IndexEscalaY,IndexEscalaX,PasEscalaY,PasEscalaX:real;
    TamanyDesti:word;
    offset:word;
    x,y:word;
    data:byte;
    Pdibuix:word;
    fiY,fiX,Cclip:longint;

begin
    IndexEscalaY:=0;  {Posar l'orige del primer pixel}
    PasEscalaY:=1/zoom;   {calcular el pas}
    PasEscalaX:=1/zoom;
    Pdibuix:=0;       {punter al dibuix}
    offset:=320*PosY+PosX; {calcular el offset desti}
    fiY:=trunc((alt-1)*zoom);  {Nou Alt}
    fiX:=Trunc((ample-1)*zoom);{nou ample}
    {comprobar que no ix de la pantalla
	   i corregir en cas contrari -> optimitzar}
    if fiY>200 then fiY:=199;
    if fiX>320 then fiX:=319;
    {escalar l'objecte fila a fila}
    for y:=0 to fiY do
    begin
     {copiar la proxima fila en el desti usant copia de memoria rapida}
     IndexEscalaX:=0;
     for x:=0 to fiX do
     begin
      data:=mem[font:Pdibuix+trunc(IndexEscalaX){+(Trunc(IndexEscalaY)*320)}];
      {comprobar transparencies}
      if data<>0 then mem[desti:offset+x]:=data;
      IndexEscalaX:=IndexEscalaX+PasEscalaX;
     end; {final per a les x}
     {usant el pas de l'escala calculem el proxim pixel font}
     IndexEscalaY:=IndexEscalaY+PasEscalaY;
     {moure el punter a la seguent linia desti}
     offset:=offset+320;
     Pdibuix:={ample}320*trunc(IndexEscalaY);
    end;{final per a les Y}
end;{final de l'escalat}


begin
end.