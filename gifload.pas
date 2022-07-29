{*****************************************************************************
**                                                                          **
**                            Unitat GIFLoad v1.0                           **
**                                                                          **
** Amb aquesta unitat podreu carregar arxius .GIF de 320x200 com a maxim en **
** els vostres jocs i programes de Pascal. Es totalment compatible amb      **
** DirectMon i els estandards de Pepe. Per als usuaris de JGU, aquesta      **
** unitat no vos fa falta.                                                  **
**                                                                          **
** Necesitareu augmentar el tamany de la pila a, al menys, 19500.           **
**                                                                          **
** Trobareu la £ltima versi¢ d'aquesta unitat a:                            **
**                                                                          **
**                  http://personal5.iddeo.es/qad/jdgames                   **
**                                                                          **
** by The JailDoctor(C) 2000                                                **
*****************************************************************************}


unit GIFLoad;

interface





procedure LoadGIF (Arxiu : String; address:word);





implementation

type
  Capsalera_del_GIF = record
    Signatura    : String [6];
    Ample,
    Alt          : Word;
    BitsPerPixel,
    Fondo,
    Zero         : Byte;
  end;
  DescriptorGIF = record
    Separador    : Char;
    Esquerra,
    Dalt,
    Ample,
    Alt          : Word;
    BitsPerPixel : Byte;
  end;


{Carrega un arxiu GIF}
procedure LoadGIF (Arxiu : String; address:word);
var
  {Per a llegir del arxiu GIF}
  Capsalera    : Capsalera_del_GIF;
  Descriptor   : DescriptorGIF;
  ArxiuGIF     : File;
  Temp         : Byte;
  BPunter      : Word;
  Buffer       : Array [0..256] of Byte;

  {Informaci¢ del color}
  BitsPerPixel,
  NumdeColors,
  DAC          : Byte;
  Paleta       : Array [0..255, 0..2] of Byte;

  {Coordenades}
  X, Y,
  tlX, tlY,
  brX, brY     : Word;

  {Les dades del GIF es guarden en blocs de cert tamany}
  TamanyDeBloc : Byte;

  {La taula de cadenes}
  Prefix       : Array [0..4096] Of Word;
  Suffix       : Array [0..4096] Of Byte;
  OutCode      : Array [0..1024] Of Byte;
  FirstFree,
  FreeCode     : Word;

  {Tota la informaci¢ dels codis}
  InitCodeSize,
  CodeSize     : Byte;
  Code,
  OldCode,
  MaxCode      : Word;

  {Codis especials}
  ClearCode,
  EOICode      : Word;

  {Per a utilitzar quan es lligen els codis}
  BitsIn       : Byte;

{Fica un registre del DAC a un valor RGB especific}
procedure SetDAC(DAC, R, G, B : Byte);
begin
  Port[$3C8] := DAC;
  Port[$3C9] := R;
  Port[$3C9] := G;
  Port[$3C9] := B;
end;

{Fica un pixel en la pantalla}
procedure PutPixel (x, y : Word; c : Byte);
begin
  Mem [address:y shl 8 + y shl 6 + x] := c;
end;


  {Funci¢ per a llegir del buffer}
  function CarregaByte : Byte;
  begin
    {Llig el segÅent bloc}
    if (BPunter = TamanyDeBloc) then begin
      {$I-}
      BlockRead (ArxiuGIF, Buffer, TamanyDeBloc + 1);
      if IOResult <> 0 then;
      {$I+}
      BPunter := 0;
    end;
    {Torna un byte}
    CarregaByte := Buffer [BPunter];
    inc (BPunter);
  end;

  {Procediment per a llegir el segÅent codi des de l'arxiu}
  procedure LligCodi;
  var
    Counter : Integer;

  begin
    Code := 0;
    {Llig el codi, bit a bit}
    for Counter := 0 To CodeSize - 1 do begin
      {Next bit}
      inc (BitsIn);

      {Un nou byte podria necessitar carregarse amb 8 bits adicionals}
      if (BitsIn = 9) then begin
        Temp := CarregaByte;
        BitsIn := 1;
      end;

      {Anyadir el bit actual al codi}
      if ((Temp and 1) > 0) then inc (Code, 1 shl Counter);
      Temp := Temp shr 1;
    end;
  end;

  {Procediment per a dibuixar un pixel}
  procedure SeguentPixel (c : Word);
  begin
    {Dibuixa el pixel en la pantalla}
    PutPixel (X, Y, c and 255);

    {Es mou al segÅent pixel}
    inc (X);

    {...o a la segÅent fila, si es necessari}
    if (X = brX) then begin
      X := tlX;
      inc (Y);
    end;
  end;

  {Funci¢ que agafa una cadena. Torna el primer caracter.}
  function AgafaCadena (CurCode : Word) : Byte;
  var
    OutCount : Word;

  begin
    {Si es un caracter nomÇs, agafa'l}
    if CurCode < 256 then begin
      SeguentPixel (CurCode);
    end else begin
      OutCount := 0;

      {Guarda la cadena, que acava en ordre invers}
      repeat
        OutCode [OutCount] := Suffix [CurCode];
        inc (OutCount);
        CurCode := Prefix [CurCode];
      until (CurCode < 256);

      {Anyadeix l'£ltim caracter}
      OutCode [OutCount] := CurCode;
      inc (OutCount);

      {Agafa tota la cadena, en l'ordre correcte}
      repeat
        dec (OutCount);
        SeguentPixel (OutCode [OutCount]);
      until OutCount = 0;
    end;
    {Torna el primer caracter}
    AgafaCadena := CurCode;
  end;

begin
  {Comprova si existeix l'arxiu GIF i l'obri. Si no el troba, fuck'em all}
  {$I-}
  Assign (ArxiuGIF, Arxiu);
  Reset (ArxiuGIF, 1);
  if IOResult <> 0 then exit;
  {$I+}

  {Llig la capáalera}
  Capsalera.Signatura [0] := Chr (6);
  Blockread (ArxiuGIF, Capsalera.Signatura [1], sizeof (Capsalera) - 1);

  {Comprova la signatura i la terminaci¢}
  if ((Capsalera.Signatura <> 'GIF87a') and (Capsalera.Signatura <> 'GIF89a'))
  or (Capsalera.Zero <> 0) then exit;

  {Comprova la profunditat de color en la imatge}
  BitsPerPixel := 1 + (Capsalera.BitsPerPixel and 7);
  NumdeColors := (1 shl BitsPerPixel) - 1;

  {Carrega el mapa de color global}
  BlockRead (ArxiuGIF, Paleta, 3 * (NumdeColors + 1));
  for DAC := 0 to NumdeColors do begin
    SetDAC(DAC, Paleta [DAC, 0] shr 2,
                Paleta [DAC, 1] shr 2,
                Paleta [DAC, 2] shr 2);
  end;

  {Carrega el descriptor de la imatge}
  BlockRead (ArxiuGIF, Descriptor, sizeof (Descriptor));

  if (Descriptor.Separador <> ',') then exit;

  {Agafa les coordenades de les vores de la imatge}
  tlX := Descriptor.Esquerra;
  tlY := Descriptor.Dalt;
  brX := tlX + Descriptor.Ample;
  brY := tlY + Descriptor.Alt;

  {Apliquem algunes restriccions}
  if (Descriptor.BitsPerPixel and 128 = 128) then exit;
  if (Descriptor.BitsPerPixel and 64 = 64) then exit;

  {Agafa el tamany incial de codi}
  BlockRead (ArxiuGIF, CodeSize, 1);

  {Les dades dels GIF es guarden en blocs, aix° Çs necessari saber el tamany}
  BlockRead (ArxiuGIF, TamanyDeBloc, 1);

  {Comenáar a carregar}
  BPunter := TamanyDeBloc;

  {Codis especials utilitzats en les especificacions del format GIF}
  ClearCode        := 1 shl CodeSize;    {Codi de reset}
  EOICode          := ClearCode + 1;     {Final de l'arxiu}

  {Inicialitzar la taula de cadenes}
  FirstFree        := ClearCode + 2;     {Les cadenes comencen ac°}
  FreeCode         := FirstFree;         {Es poden anyadir mÇs cadenes ac°}

  {Tamany inicial del codi i el seu valor maxim}
  inc (CodeSize);
  InitCodeSize     := CodeSize;
  MaxCode          := 1 shl CodeSize;

  BitsIn := 8;

  {Comenáar a la vora de Dalt a la esquerra de la imatge}
  X := Descriptor.Esquerra;
  Y := Descriptor.Dalt;


  {ALGORISME DE DESCOMPRESI‡ LZH}
  repeat
    {Llegir el segÅent codi}
    LligCodi;

    {Si es un codi Final-De-Informaci¢, parar}
         if Code = EOICode then break
    {Si es un codi de reset...}
    else if Code = ClearCode then begin
      {Borrar la taula de cadenes}
      FreeCode := FirstFree;

      {Ficar el tamany del codi al seu valor inicial}
      CodeSize := InitCodeSize;
      MaxCode  := 1 shl CodeSize;

      {El segÅent codi es deu de llegir}
      LligCodi;
      OldCode := Code;

      {Especifica el pixel}
      SeguentPixel (Code);
    {Altres codis}
    end else begin
      {Si el codi ja estÖ en la taula de cadenes, exia cadena es dibuixarÖ,
      i l'antiga cadena seguida del primer caracter de la nova s'anyadeix
      a la taula de cadenes.}
      if (Code < FreeCode) then
        Suffix [FreeCode] := AgafaCadena (Code)
      else begin
      {Si encara no estÖ en la taula de cadenes, l'antiga cadena seguida del
      primer caracter de la mateixa s'anyadeix a la taula de cadenes i es
      dibuixa.}
        Suffix [FreeCode] := AgafaCadena (OldCode);
        SeguentPixel (Suffix [FreeCode]);
      end;

      {Acavar anyadint-la a la taula de cadenes}
      Prefix [FreeCode] := OldCode;
      inc (FreeCode);

      {Si fa falta ajustar el tamany del codi, fer-ho}
      if (FreeCode >= MaxCode) and (CodeSize < 12) then begin
        inc (CodeSize);
        MaxCode := MaxCode shl 1;
      end;

      {L'actual codi es ara l'antic}
      OldCode := Code;
    end;

  until Code = EOICode;

  {Tanca l'arxiu GIF}
  Close (ArxiuGIF);
end;


begin

end.