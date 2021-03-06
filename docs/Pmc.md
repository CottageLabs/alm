[PubMed Central](http://www.ncbi.nlm.nih.gov/pmc/) is a free full-text archive of biomedical and life sciences journal literature at the U.S. National Institutes of Health's National Library of Medicine. PubMed Central usage stats are available to publishers of these journal articles. The usage stats are available as individual XML files for a given journal, month and year.

<table width=100% border="0" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td valign="top" width=20%><strong>ALM Name</strong></td>
<td valign="top" width=80%>pmc</td>
</tr>
<tr>
<td valign="top" width=20%><strong>ALM Configuration</strong></td>
<td valign="top" width=80%>default</td>
</tr>
<tr>
<td valign="top" width=20%><strong>ALM Core Attributes</strong></td>
<td valign="top" width=80%>id (as doi, pmid and pmcid)</td>
</tr>
<td valign="top" width=20%><strong>ALM Other Attributes</strong></td>
<td valign="top" width=80%>none</td>
</tr>
<tr>
<td valign="top" width=30%><strong>Protocol</strong></td>
<td valign="top" width=70%>HTTP</td>
</tr>
<tr>
<td valign="top" width=30%><strong>Format</strong></td>
<td valign="top" width=70%>XML</td>
</tr>
<tr>
<td valign="top" width=20%><strong>Rate-limiting</strong></td>
<td valign="top" width=80%>unknown</td>
</tr>
<tr>
<td valign="top" width=20%><strong>Authentication</strong></td>
<td valign="top" width=80%>yes</td>
</tr>
<tr>
<td valign="top" width=20%><strong>Restriction by IP Address</strong></td>
<td valign="top" width=80%>no</td>
</tr>
<tr>
<td valign="top" width=20%><strong>API URL</strong></td>
<td valign="top" width=80%>http://www.pubmedcentral.nih.gov/utils/publisher/pmcstat/pmcstat.cgi?year=YEAR&month=MONTH&jrid=JOURNAL&user=USERNAME&password=PASSWORD</td>
</tr>
</tbody>
</table>

## Example (excerpt)

```xml
<pmc-web-stat>
  <request year="2013" month="10" jrid="plosbiol" issn="1544-9173" eissn="1545-7885"></request>
  <response status="0" collection="PLoS Biol"></response>
  <articles>
    <article id="PMC1043859">
      <meta-data doi="10.1371/journal.pbio.0030060" pmcid="PMC1043859" pubmed-id="15736975" pub-year="2005" volume="3" issue="4" first-page="e60"/>
      <usage unique-ip="3" full-text="1" pdf="1" abstract="0" scanned-summary="0" scanned-page-browse="0" figure="4" supp-data="0" cited-by="0"/>
    </article>
    <article id="PMC1043860">
      <meta-data doi="10.1371/journal.pbio.0030085" pmcid="PMC1043860" pubmed-id="15723116" pub-year="2005" volume="3" issue="3" first-page="e85"/>
      <usage unique-ip="118" full-text="128" pdf="90" abstract="2" scanned-summary="0" scanned-page-browse="0" figure="13" supp-data="0" cited-by="1"/>
    </article>
    <article id="PMC1043861">
      <meta-data doi="10.1371/journal.pbio.0030114" pmcid="PMC1043861" pubmed-id="0" pub-year="2005" volume="3" issue="3" first-page="e114"/>
      <usage unique-ip="4" full-text="4" pdf="0" abstract="0" scanned-summary="0" scanned-page-browse="0" figure="0" supp-data="0" cited-by="0"/>
    </article>
    <article id="PMC1043862">
      <meta-data doi="10.1371/journal.pbio.0030122" pmcid="PMC1043862" pubmed-id="15736988" pub-year="2005" volume="3" issue="4" first-page="e122"/>
      <usage unique-ip="1" full-text="1" pdf="1" abstract="0" scanned-summary="0" scanned-page-browse="0" figure="0" supp-data="0" cited-by="0"/>
    </article>
    <article id="PMC1044830">
      <meta-data doi="10.1371/journal.pbio.0030063" pmcid="PMC1044830" pubmed-id="15736976" pub-year="2005" volume="3" issue="3" first-page="e63"/>
      <usage unique-ip="29" full-text="25" pdf="6" abstract="7" scanned-summary="0" scanned-page-browse="0" figure="0" supp-data="0" cited-by="0"/>
    </article>
    <article id="PMC1044831">
      <meta-data doi="10.1371/journal.pbio.0030064" pmcid="PMC1044831" pubmed-id="15736977" pub-year="2005" volume="3" issue="3" first-page="e64"/>
      <usage unique-ip="10" full-text="10" pdf="2" abstract="0" scanned-summary="0" scanned-page-browse="0" figure="0" supp-data="0" cited-by="0"/>
    </article>
    <article id="PMC1044832">
      <meta-data doi="10.1371/journal.pbio.0030071" pmcid="PMC1044832" pubmed-id="15736978" pub-year="2005" volume="3" issue="3" first-page="e71"/>
      <usage unique-ip="8" full-text="10" pdf="1" abstract="0" scanned-summary="0" scanned-page-browse="0" figure="0" supp-data="0" cited-by="0"/>
    </article>
  </articles>
</pmc-web-stat>
```

## Source Code
The source code is available [here](https://github.com/articlemetrics/alm/blob/master/app/models/sources/pmc.rb).

## Further Documentation
* [PubMed Central usage stats](http://www.ncbi.nlm.nih.gov/pmc/about/faq/#q26)