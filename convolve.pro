FUNCTION convolve, img1, img2, dimx, dimy, DIMZ=dimz, MAT=mat, NOOUT=noout, CORR=corr
; Function for computing the convolution or cross-correlation between a template-image and an image

  nparam= n_params()
  IF (nparam lt 4) then BEGIN
    print, 'Input: convolve, <file1>, <file2>, dimx, dimy, [dimz=z], [/mat], [/noout], [/corr'
    print, 'Set /mat keyword to select array form of input:'
    print, 'When /mat is set, replace <file1> and <file2> with array names <dat1> and <dat2>'
    print, '/noout disables writing to std. out'
    print, '/corr enables cross-correlation'
    print, 'Number of parameters required for CONVOLVE= 4'
    print, 'Number of parameters passed= ', nparam
    print, 'Program zero-pads inputs to 2x dimensions'
    RETURN, 1
  ENDIF

  close, 1
  IF(NOT KEYWORD_SET(dimz)) THEN dimz= 1

  dat1= fltarr(dimx,dimy,dimz)
  dat2= fltarr(dimx,dimy,dimz)
  padx= dimx/2
  pady= dimy/2
  padz= dimz/2
  dimpx= dimx+2*padx
  dimpy= dimy+2*pady
  dimpz= dimz+2*padz
  roi= bytarr(dimpx,dimpy,dimpz)
  roi[*,*,*]= 0
  roi[padx:dimx+padx-1,pady:dimy+pady-1,padz:dimz+padz-1]= 1
  rind= WHERE(roi eq 1)
  nrind= 1.0*dimpx*dimpy*dimpz
  IF(KEYWORD_SET(mat)) THEN BEGIN
    dat1= img1
    dat2= img2
  ENDIF ELSE BEGIN
    openr, 1, img1
    readu, 1, dat1
    close, 1
    openr, 1, img2
    readu, 1, dat2
    close, 1
  ENDELSE
  if(NOT KEYWORD_SET(noout)) THEN BEGIN
    print, 'Padding: ', dimx, dimy, dimz, ' --> ', dimpx, dimpy, dimpz
  ENDIF
  datp= dblarr(dimpx,dimpy,dimpz)
  datp[rind]= dat1
  ft1= FFT(datp, -1, /DOUBLE)
  datp[rind]= dat2
  ft2= FFT(datp, -1, /DOUBLE)
  if(KEYWORD_SET(corr)) THEN ft2= CONJ(ft2)
  ft= nrind*ft1*ft2
  ift= FLOAT(FFT(ft, 1, /DOUBLE))
  if (dimz eq 1) then tmp= SHIFT(ift,dimx,dimy) else tmp= SHIFT(ift,dimx,dimy,dimz)
  if (dimz eq 1) then img= REFORM(tmp[rind],dimx,dimy) else img= REFORM(tmp[rind],dimx,dimy,dimz)
  RETURN, img
END

