#!/usr/bin/env python
import json
import re, sys, codecs, urllib2
from bs4 import BeautifulSoup

url='http://www.eltrecetv.com.ar/capitulos-completos'
request = urllib2.Request(url)
o = urllib2.urlopen(request)
soup = BeautifulSoup(o)

print '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
print '<feed>'
for i in soup.find('div', class_="view-capitulos-completos") \
             .find_all('div', class_="views_row"):
   item = {}
   a = i.find('a')
   uri = 'http://www.eltrecetv.com.ar%s' % a['href']

   item['img'] = a.find('img')['src']
   item['title'] = a.find('img')['alt']
   
   r = BeautifulSoup(urllib2.urlopen(urllib2.Request(uri)))
   x = r.find_all('div', class_="video-eltrece")
   i=x[0]
   item['duration'] = i.attrs['data-duration']

   item['uri'] = 'http://vod.eltrecetv.com.ar:1935/vod/13tv/mp4:%s/playlist.m3u8' % json.loads(i.attrs['data-levels'])[-1]['file']
   item['description']=r.find('div', itemprop="description").p.text

   print '  <item sdImg="%s" ' % item['img']
   print '        hdImg="%s">' % item['img']
   print '    <title><![CDATA[%s]]></title>' % item['title'].encode('utf-8')
   print '    <streamFormat>hls</streamFormat>'
   print '    <media>'
   print '      <streamUrl>%s</streamUrl>' % item['uri']
   print '    </media>'
   print '    <runtime>%s</runtime>' % item['duration']
   print '    <synopsis><![CDATA[%s]]></synopsis>' % item['description'].encode('utf-8')
   print '  </item>'
print '</feed>'
