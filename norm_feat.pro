ft_data=fltarr(8,315)
openr,1,'feat_file'
readf,1,ft_data
free_lun,1

i=0
nomultcand=0 ;counter for number of images with more than 1 candidate
meanfeatarr=fltarr(4,315) ;array for storing mean of features for images with multiple candidates
stdfeatarr=fltarr(4,315) ;array for storing std deviations of features for images with multiple candidates
singlecandarr=fltarr(315) ;image indices for single candidate images
nosinglecand=0 ;counter for number of images with exactly 1 candidate
openw,1,'norm_feat_file'


FORMAT = '(3F0)'
while (i lt 315) do begin
  fid=ft_data[7,i] ;file id
  fil_feat=fltarr(8,5) ;features for various candidtes in present file
  j=0
  while (i+j lt 315) && (ft_data[7,i+j] eq fid) do begin
    fil_feat[*,j]=ft_data[*,i+j]
    j=j+1
  endwhile
  fil_feat=fil_feat[*,0:j-1]
  
  npts=(size(transpose(fil_feat)))[1] ;no of candidates in present file
  
  
  if (npts gt 1) then begin
    for feat=3,6 do begin
      meanfeat=mean(fil_feat[feat,*])
      stdfeat=stddev(fil_feat[feat,*])
      meanfeatarr[feat-3,nomultcand]=meanfeat
      stdfeatarr[feat-3,nomultcand]=stdfeat
      for cand=0,j-1 do begin
        fil_feat[feat,cand]=(fil_feat[feat,cand]-meanfeat)/stdfeat
      endfor
  endfor
  
  for cand=0,j-1 do begin
    ob_ev=strtrim(string(fix(fil_feat[0,cand])),2)+' 0 '
    ;human_ev=' 0 '
     features=strtrim(string(fil_feat(2:6,cand)),2)
     id=strtrim(string(fix(fil_feat[7,cand])),2)+' '
     ;print,fil_feat
     printf,1,ob_ev,features[0],' ',features[1],' ',features[2],' ',features[3],' ',features[4]+' ',id
  endfor
  ;printf,1,fil_feat
  nomultcand=nomultcand+1
  endif else begin
    singlecandarr[nosinglecand]=fil_feat[7]
    nosinglecand=nosinglecand+1
  endelse
  i=i+j
endwhile

classmean=fltarr(4)
classstd=fltarr(4)
for feat=0,3 do begin
  classmean[feat]=mean(meanfeatarr[feat,0:nomultcand-1])
  classstd[feat]=mean(stdfeatarr[feat,0:nomultcand-1])
endfor

fil_feat=fltarr(8)
fid=ft_data[7,*]
for i=0,nosinglecand-1 do begin
  img=singlecandarr[i]
  pos=where(fid eq img)
  fil_feat=ft_data[*,pos]
  for feat=3,6 do begin
    fil_feat[feat]=(fil_feat[feat]-classmean[feat-3])/classstd[feat-3]
  endfor
  ob_ev=strtrim(string(fix(fil_feat[0])),2)+' 0 '
  ;human_ev=' 0 '
  features=strtrim(string(fil_feat(2:6)),2)
  id=strtrim(string(fix(fil_feat[7])),2)+' '
  printf,1,ob_ev,features[0],' ',features[1],' ',features[2],' ',features[3],' ',features[4],' ',id
endfor
free_lun,1
end
