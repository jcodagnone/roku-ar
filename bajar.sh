#!/bin/bash

# convierte en rss 

##############################################################################
## TELEFE
function telefe() {
   echo telefe
   telefeshow $1/srespapis   80295
   telefeshow $1/masterchef 123984
   telefeshow $1/somosfamilia 12174
   telefeshow $1/peligrosincodificar 10592
}

#recibe un string que tiene un json y saca una lista de urls de capitulos
# saca una lista como 
# http://telefe.com/masterchef/masterchef-programa-1-(06-04-2014)/
# http://telefe.com/sres-papis/sres-papis-capitulo-64-(29-04-2014)/
function tocapitulourl() {

   # "{\"PageNumber\":\"1\",\"ItemsPerPage\":\"12
   sed 's/\\\"/"/g'|  #"{"PageNumber":"1","ItemsPerPage":"12",
   sed 's/^"//g'|
   sed 's/"$//g'|     # {"PageNumber":"1","ItemsPerPage":"12",
   python -m json.tool|
   grep '"Link":'|
   cut -d'"' -f4 

}

# recibe un link como 
#    http://telefe.com/masterchef/masterchef-programa-1-(06-04-2014)/
# y retorna una fecha en formato ISO-DATE
function link2date() {
   awk 'BEGIN{FS="/"}{print $(NF-1)}'|     # masterchef-programa-4-(27-04-2014)
   awk 'BEGIN{FS="("}{print $(NF)}'  |     # 27-04-2014)
   awk 'BEGIN{FS=")"}{print $1}'     |     # 27-04-2014
   awk 'BEGIN{FS="-"}{print $3"-"$2"-"$1}' # 2014-04-27

}

function telefeshow() {
   curl -s "http://telefe.com/umbraco/surface/TelefeMicrositiosSurface/GetVerMas?categoryId=11&nodeId=$2&page=" > .x || exit 1
   cat .x|tocapitulourl > .links

  # en links hay links de la forma
  # http://telefe.com/sres-papis/sres-papis-capitulo-65-(30-04-2014)/
  for i in `cat .links`; do
     d=`echo $i|link2date`
     prefix="$1/$d"
     out=${prefix}.html
     xml=${prefix}.xml
     if  [ ! -e $out ]; then
        if  [ ! -e $xml ]; then
          echo $i to $out
          curl -s $i > .tmp
          mv .tmp  $out
        fi
     fi

     if  [ ! -e $xml ]; then
      img=`cat $out|grep 'og:image'|sed 's/^.*content="//g'|cut -d'"' -f1`
      title=`cat $out|grep '<meta name="description"'|sed 's/^.*content="//g'|cut -d'"' -f1|sed 's/(.*$//g'|cut -d- -f2-|cut -b2-`"($d)"
      mp4url=`cat $out|egrep  'edgesuite'|cut -d'"' -f 4`
      descr=`cat $out |grep 'og:description'|sed 's/^.*content="//g'|cut -d'"' -f1`
      cat << EOF | xmllint --format --nocatalogs - |sed 1d > .tmp
<item sdImg="${img}" 
      hdImg="${img}">
  <title>${title}</title>
  <streamFormat>mp4</streamFormat>
  <media>
    <streamUrl>${mp4url}</streamUrl>
  </media>
  <synopsis>${descr}</synopsis>
</item> 

EOF
   mv .tmp $xml
   rm $out
fi
  o="$1/index.xml"
  echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'  > $o
  echo '<feed>' >> $o
  ls $1/2*.xml|sort -r|head -n 20|xargs cat >> $o
  echo '</feed>' >> $o
  done
   
}

###############################################################################
content="content"
telefe $content/telefe
echo trece
./eltrece.py > content/eltrece/index.xml



out="$content/categories.xml"
base="http://tvar.s3.amazonaws.com"
cat << EOF > $out
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<categories>
        <category title="Todo Noticias" 
                  description="TN"
                  sd_img="$base/tn/logo.png"
                  hd_img="$base/tn/logo.png">
                <categoryLeaf title="TN" 
                              description=""
                              feed="$base/tn/index.xml"/>
        </category>
        <category title="Telefe" 
                  description="LS 84 TV Canal 11 de Televisión
argentina,transmitiendo desde la ciudad de Buenos Aires" 
                  sd_img="$base/telefe/logo.png"
                  hd_img="$base/telefe/logo.png">
                <categoryLeaf title="Mastercheff" 
                              description=""
                              feed="$base/telefe/masterchef/index.xml"/>
                <categoryLeaf title="Sres Papis"
                              description=""
                              feed="$base/telefe/srespapis/index.xml"/>
                <categoryLeaf title="Somos Familia"
                              description=""
                              feed="$base/telefe/somosfamilia/index.xml"/>
                <categoryLeaf title="Peligro sin codificar"
                              description=""
                              feed="$base/telefe/peligrosincodificar/index.xml"/>
        </category>
        <category title="El Trece" 
                  description="LS 85 TV Canal 13 de Televisión argentina, transmitiendo desde la ciudad de Buenos Aires" 
                  sd_img="$base/eltrece/logo.png"
                  hd_img="$base/eltrece/logo.png">
                <categoryLeaf title="Últimos capitulos" 
                              description=""
                              feed="$base/eltrece/index.xml"/>
                <categoryLeaf title="Vivo"
                              description=""
                              feed="$base/eltrece/vivo.xml"/>
        </category>
 </categories>
EOF

s3cmd sync -c ~/.s3cfg-leak -P --exclude=201* content/ s3://tvar/

