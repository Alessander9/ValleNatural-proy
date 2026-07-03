$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outFile = Join-Path $root 'datosValleNatural.txt'

function Normalize-Text {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return '' }

  $clean = $Text
  $clean = $clean -replace '(?s)<script\b.*?</script>', ' '
  $clean = $clean -replace '(?s)<style\b.*?</style>', ' '
  $clean = $clean -replace '<br\s*/?>', ' '
  $clean = $clean -replace '<[^>]+>', ' '
  $clean = [System.Net.WebUtility]::HtmlDecode($clean)
  $clean = ($clean -replace '\s+', ' ').Trim()
  return $clean
}

function Get-FirstMatch {
  param(
    [string]$Text,
    [string]$Pattern,
    [int]$Group = 1
  )

  $m = [regex]::Match($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if ($m.Success) {
    return $m.Groups[$Group].Value
  }
  return ''
}

function Get-AllMatches {
  param(
    [string]$Text,
    [string]$Pattern,
    [int]$Group = 1
  )

  $results = @()
  foreach ($m in [regex]::Matches($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
    if ($m.Success) {
      $results += $m.Groups[$Group].Value
    }
  }
  return $results
}

function Format-Block {
  param(
    [string[]]$Lines,
    [int]$Indent = 0
  )

  $pad = ' ' * $Indent
  return ($Lines | ForEach-Object { "$pad$_" }) -join [Environment]::NewLine
}

function Add-Line {
  param([System.Collections.Generic.List[string]]$Buffer, [string]$Line = '')
  [void]$Buffer.Add($Line)
}

function Extract-PriceInfo {
  param([string]$Text)

  $oldPrice = Get-FirstMatch $Text '<span class="old-price">\s*([^<]+?)\s*</span>'
  $priceMatches = [regex]::Matches($Text, 'S/\s*[0-9]+(?:\.[0-9]{2})?', [System.Text.RegularExpressions.RegexOptions]::Singleline)
  $currentPrice = ''
  if ($priceMatches.Count -gt 0) {
    $currentPrice = $priceMatches[$priceMatches.Count - 1].Value
  }

  [pscustomobject]@{
    Current = $currentPrice
    Old     = $oldPrice
  }
}

function Extract-Card {
  param([string]$Chunk)

  $outerHref = Get-FirstMatch $Chunk '^\s*<(?:a|div)\b[^>]*href="([^"]+)"'
  $imgSrc = Get-FirstMatch $Chunk '<img[^>]*src="([^"]+)"'
  $imgAlt = Get-FirstMatch $Chunk '<img[^>]*alt="([^"]*)"'
  $title = Normalize-Text (Get-FirstMatch $Chunk '<h3[^>]*>(.*?)</h3>')
  $note = Normalize-Text (Get-FirstMatch $Chunk '<(?:div|p)[^>]*class="[^"]*(?:delivery-info|text-gray-600)[^"]*"[^>]*>(.*?)</(?:div|p)>')
  $detailHref = Get-FirstMatch $Chunk '<a[^>]*href="([^"]+)"[^>]*class="[^"]*(?:btn-detail|add-to-cart-btn(?:-full)?)'
  $waHref = Get-FirstMatch $Chunk 'https://wa\.me/[^"]+'
  $prices = Extract-PriceInfo $Chunk
  $badge = Normalize-Text (Get-FirstMatch $Chunk '<div class="offer-badge">(.*?)</div>')

  [pscustomobject]@{
    OuterHref  = $outerHref
    Image      = $imgSrc
    Alt        = $imgAlt
    Title      = $title
    Note       = $note
    Price      = $prices.Current
    OldPrice   = $prices.Old
    DetailHref = $detailHref
    WhatsApp   = $waHref
    Badge      = $badge
  }
}

function Extract-ModernCard {
  param([string]$Chunk)

  $imgSrc = Get-FirstMatch $Chunk '<img[^>]*src="([^"]+)"'
  $imgAlt = Get-FirstMatch $Chunk '<img[^>]*alt="([^"]*)"'
  $title = Normalize-Text (Get-FirstMatch $Chunk '<h3[^>]*>(.*?)</h3>')
  $price = Normalize-Text (Get-FirstMatch $Chunk '<div[^>]*class="price"[^>]*>.*?(S/\s*[0-9]+(?:\.[0-9]{2})?)')
  $badge = Normalize-Text (Get-FirstMatch $Chunk '<span class="badge-type">.*?<span class="material-icons">[^<]+</span>\s*(.*?)</span>')
  $dataName = Get-FirstMatch $Chunk 'data-name="([^"]+)"'
  $dataCat = Get-FirstMatch $Chunk 'data-cat="([^"]+)"'
  $dataStock = Get-FirstMatch $Chunk 'data-stock="([^"]+)"'
  $dataOffer = Get-FirstMatch $Chunk 'data-offer="([^"]+)"'
  $waHref = Get-FirstMatch $Chunk 'https://wa\.me/[^"]+'
  $detailHref = Get-FirstMatch $Chunk '<a[^>]*href="([^"]+)"[^>]*class="btn-detail"'

  $pillTexts = @()
  foreach ($pill in [regex]::Matches($Chunk, '<span class="pill"><span class="material-icons">[^<]+</span>\s*([^<]+)</span>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
    $txt = Normalize-Text $pill.Groups[1].Value
    if ($txt) { $pillTexts += $txt }
  }

  [pscustomobject]@{
    Image      = $imgSrc
    Alt        = $imgAlt
    Title      = $title
    Price      = $price
    Badge      = $badge
    DataName   = $dataName
    DataCat    = $dataCat
    DataStock  = $dataStock
    DataOffer  = $dataOffer
    Pills      = $pillTexts
    DetailHref = $detailHref
    WhatsApp   = $waHref
  }
}

function Extract-CategoryCard {
  param([string]$Chunk)

  $outerHref = Get-FirstMatch $Chunk '^\s*<a[^>]*href="([^"]+)"'
  $imgSrc = Get-FirstMatch $Chunk '<img[^>]*src="([^"]+)"'
  $imgAlt = Get-FirstMatch $Chunk '<img[^>]*alt="([^"]*)"'
  $title = Normalize-Text (Get-FirstMatch $Chunk '<h3[^>]*>(.*?)</h3>')
  $description = Normalize-Text (Get-FirstMatch $Chunk '<p[^>]*class="text-gray-600"[^>]*>(.*?)</p>')
  $cta = Normalize-Text (Get-FirstMatch $Chunk '<div[^>]*class="mt-4 inline-flex items-center gap-2 font-bold"[^>]*>(.*?)</div>')

  [pscustomobject]@{
    Href        = $outerHref
    Image       = $imgSrc
    Alt         = $imgAlt
    Title       = $title
    Description = $description
    Cta         = $cta
  }
}

function Extract-DetailPage {
  param(
    [string]$FileName,
    [string]$Html
  )

  $pageTitle = Normalize-Text (Get-FirstMatch $Html '<title>(.*?)</title>')
  $metaDescription = Normalize-Text (Get-FirstMatch $Html '<meta[^>]*name="description"[^>]*content="([^"]+)"')
  $h1 = Normalize-Text (Get-FirstMatch $Html '<h1[^>]*>(.*?)</h1>')
  $imageSrc = Get-FirstMatch $Html '<img[^>]*src="([^"]+)"[^>]*alt="[^"]*"'
  $imageAlt = Get-FirstMatch $Html '<img[^>]*src="[^"]+"[^>]*alt="([^"]*)"'
  $description = Normalize-Text (Get-FirstMatch $Html '<p[^>]*class="text-gray-700[^"]*mb-5[^"]*"[^>]*>(.*?)</p>')
  $price = Normalize-Text (Get-FirstMatch $Html '<span[^>]*class="text-3xl[^"]*"[^>]*>\s*<span class="material-icons">sell</span>\s*(S/\s*[0-9]+(?:\.[0-9]{2})?)')
  $oldPrice = Normalize-Text (Get-FirstMatch $Html '<span[^>]*class="text-gray-400 line-through text-lg"[^>]*>([^<]+)</span>')
  $presentationOptions = @()
  foreach ($opt in [regex]::Matches($Html, '<option[^>]*>(.*?)</option>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
    $text = Normalize-Text $opt.Groups[1].Value
    if ($text) { $presentationOptions += $text }
  }

  $availability = Normalize-Text (Get-FirstMatch $Html '<div[^>]*id="stockBox"[^>]*>(.*?)</div>')
  $utilityItems = @()
  $utilityBlock = Get-FirstMatch $Html '(?s)<div class="mt-8 utility-box">.*?<ul class="space-y-2 text-gray-700">(.*?)</ul>'
  if ($utilityBlock) {
    foreach ($li in [regex]::Matches($utilityBlock, '<li[^>]*>(.*?)</li>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
      $item = Normalize-Text $li.Groups[1].Value
      if ($item) { $utilityItems += $item }
    }
  }

  $tech = @()
  $techBlock = Get-FirstMatch $Html '(?s)<div class="mt-6 tech-box">.*?<div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm"[^>]*>(.*?)</div>\s*</div>\s*</div>'
  if ($techBlock) {
    foreach ($field in [regex]::Matches($techBlock, '<div><span class="font-semibold">([^<:]+):</span>\s*(.*?)</div>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
      $tech += [pscustomobject]@{
        Label = Normalize-Text $field.Groups[1].Value
        Value = Normalize-Text $field.Groups[2].Value
      }
    }
  }

  [pscustomobject]@{
    File            = $FileName
    PageTitle       = $pageTitle
    MetaDescription = $metaDescription
    H1             = $h1
    Image          = $imageSrc
    ImageAlt       = $imageAlt
    Description    = $description
    Price          = $price
    OldPrice       = $oldPrice
    Presentations  = $presentationOptions
    Availability   = $availability
    UtilityItems   = $utilityItems
    TechFields     = $tech
  }
}

function Get-CardChunks {
  param([string]$Html)

  $pattern = '(?s)<(?:div|a)\b[^>]*class="[^"]*\b(?:offer-card|card)\b[^"]*"[^>]*>'
  $matches = [regex]::Matches($Html, $pattern)
  $chunks = @()
  if ($matches.Count -eq 0) {
    return $chunks
  }

  for ($i = 0; $i -lt $matches.Count; $i++) {
    $start = $matches[$i].Index
    $end = if ($i -lt $matches.Count - 1) { $matches[$i + 1].Index } else { $Html.Length }
    $chunks += $Html.Substring($start, $end - $start)
  }

  return $chunks
}

$files = Get-ChildItem -Path $root -Filter *.html | Sort-Object Name
$report = New-Object System.Collections.Generic.List[string]

Add-Line $report '# datosValleNatural'
Add-Line $report ''
Add-Line $report 'Volcado estructurado del contenido visible de las vistas HTML del proyecto Valle Natural.'
Add-Line $report ''
Add-Line $report '## Resumen'
Add-Line $report ''
Add-Line $report ("Archivos HTML analizados: {0}" -f $files.Count)
Add-Line $report 'Nota: las páginas sin catálogo visible o vacías se reportan como referencia de vista.'
Add-Line $report ''

foreach ($file in $files) {
  $html = Get-Content -LiteralPath $file.FullName -Raw
  Add-Line $report ("## Archivo: {0}" -f $file.Name)
  Add-Line $report ''

  if ([string]::IsNullOrWhiteSpace($html)) {
    Add-Line $report 'Contenido: archivo vacío.'
    Add-Line $report ''
    continue
  }

  $pageTitle = Normalize-Text (Get-FirstMatch $html '<title>(.*?)</title>')
  if ($pageTitle) {
    Add-Line $report ("Título: {0}" -f $pageTitle)
  }

  $metaDescription = Normalize-Text (Get-FirstMatch $html '<meta[^>]*name="description"[^>]*content="([^"]+)"')
  if ($metaDescription) {
    Add-Line $report ("Meta description: {0}" -f $metaDescription)
  }

  if ($file.Name -eq 'DetalleProducto.html') {
    Add-Line $report ''
    Add-Line $report 'Tipo: plantilla dinámica de detalle de producto.'
    Add-Line $report 'Fuente de datos: colección Firestore `productos`.'
    Add-Line $report 'Campos visibles en la plantilla: nombre, descripción, precio, imagen, presentación, stock, ficha técnica y botones de compra.'
    Add-Line $report ''
    Add-Line $report 'Secciones detectadas:'
    Add-Line $report ' - Título y breadcrumb dinámico'
    Add-Line $report ' - Imagen principal'
    Add-Line $report ' - Descripción'
    Add-Line $report ' - Precio'
    Add-Line $report ' - Presentación'
    Add-Line $report ' - Disponibilidad'
    Add-Line $report ' - Métodos de pago'
    Add-Line $report ' - Ficha técnica'
    Add-Line $report ' - Relacionados'
    Add-Line $report ''
    continue
  }

  if ($file.Name -eq 'admin.html') {
    Add-Line $report ''
    Add-Line $report 'Vista administrativa. No expone catálogo de productos en contenido visible principal.'
    Add-Line $report ''
    continue
  }

  if ($file.Name -eq 'Movimiento.html') {
    Add-Line $report ''
    Add-Line $report 'Vista vacía o sin contenido detectado.'
    Add-Line $report ''
    continue
  }

  $detailLike = $html -match 'product-info' -and $html -match 'utility-box'
  if ($detailLike) {
    $detail = Extract-DetailPage -FileName $file.Name -Html $html

    Add-Line $report 'Tipo: ficha de producto.'
    if ($detail.H1) { Add-Line $report ("Producto: {0}" -f $detail.H1) }
    if ($detail.MetaDescription) { Add-Line $report ("Meta description: {0}" -f $detail.MetaDescription) }
    if ($detail.Image) { Add-Line $report ("Imagen: {0}" -f $detail.Image) }
    if ($detail.ImageAlt) { Add-Line $report ("Alt imagen: {0}" -f $detail.ImageAlt) }
    if ($detail.Description) { Add-Line $report ("Descripción: {0}" -f $detail.Description) }
    if ($detail.Price) { Add-Line $report ("Precio: {0}" -f $detail.Price) }
    if ($detail.OldPrice) { Add-Line $report ("Precio anterior: {0}" -f $detail.OldPrice) }
    if ($detail.Presentations.Count -gt 0) {
      Add-Line $report 'Presentaciones:'
      foreach ($p in $detail.Presentations) { Add-Line $report (" - {0}" -f $p) }
    }
    if ($detail.Availability) { Add-Line $report ("Disponibilidad: {0}" -f $detail.Availability) }
    if ($detail.UtilityItems.Count -gt 0) {
      Add-Line $report 'Utilidad:'
      foreach ($item in $detail.UtilityItems) { Add-Line $report (" - {0}" -f $item) }
    }
    if ($detail.TechFields.Count -gt 0) {
      Add-Line $report 'Ficha técnica:'
      foreach ($t in $detail.TechFields) { Add-Line $report (" - {0}: {1}" -f $t.Label, $t.Value) }
    }
    Add-Line $report ''
    continue
  }

  $chunks = Get-CardChunks $html
  if ($chunks.Count -gt 0) {
    $hasCategoryCards = $false
    $hasProductCards = $false
    $hasModernCards = $false
    foreach ($chunk in $chunks) {
      if ($chunk -match 'data-name=.*data-cat=.*btn-detail' -or $chunk -match '<div class="card gsap-prod"') { $hasModernCards = $true }
      if ($chunk -match 'btn-detail|add-to-cart-btn|delivery-info') { $hasProductCards = $true }
      if ($chunk -match 'text-gray-600.*Ver productos|Ver productos') { $hasCategoryCards = $true }
    }

    if ($hasModernCards) {
      Add-Line $report 'Tipo: vista de catálogo temático.'
      Add-Line $report ''
      $n = 1
      foreach ($chunk in $chunks) {
        if ($chunk -notmatch 'class="card gsap-prod"') { continue }
        $card = Extract-ModernCard $chunk
        Add-Line $report ("Producto {0}:" -f $n)
        if ($card.Title) { Add-Line $report (" - Nombre: {0}" -f $card.Title) }
        if ($card.Badge) { Add-Line $report (" - Etiqueta: {0}" -f $card.Badge) }
        if ($card.Image) { Add-Line $report (" - Imagen: {0}" -f $card.Image) }
        if ($card.Alt) { Add-Line $report (" - Alt imagen: {0}" -f $card.Alt) }
        if ($card.Price) { Add-Line $report (" - Precio: {0}" -f $card.Price) }
        if ($card.DataName) { Add-Line $report (" - Slug: {0}" -f $card.DataName) }
        if ($card.DataCat) { Add-Line $report (" - Categoría interna: {0}" -f $card.DataCat) }
        if ($card.DataStock) { Add-Line $report (" - Stock: {0}" -f $card.DataStock) }
        if ($card.DataOffer) { Add-Line $report (" - Oferta: {0}" -f $card.DataOffer) }
        if ($card.Pills.Count -gt 0) {
          Add-Line $report (' - Atributos: ' + ($card.Pills -join ' | '))
        }
        if ($card.DetailHref) { Add-Line $report (" - Detalle: {0}" -f $card.DetailHref) }
        if ($card.WhatsApp) { Add-Line $report (" - WhatsApp: {0}" -f $card.WhatsApp) }
        Add-Line $report ''
        $n++
      }
      continue
    }

    if ($hasProductCards) {
      Add-Line $report 'Tipo: vista de catálogo / tarjetas de producto.'
      Add-Line $report ''
      $n = 1
      foreach ($chunk in $chunks) {
        if ($chunk -notmatch 'btn-detail|add-to-cart-btn|delivery-info') { continue }
        $card = Extract-Card $chunk
        Add-Line $report ("Producto {0}:" -f $n)
        if ($card.Title) { Add-Line $report (" - Nombre: {0}" -f $card.Title) }
        if ($card.Badge) { Add-Line $report (" - Etiqueta: {0}" -f $card.Badge) }
        if ($card.Image) { Add-Line $report (" - Imagen: {0}" -f $card.Image) }
        if ($card.Alt) { Add-Line $report (" - Alt imagen: {0}" -f $card.Alt) }
        if ($card.Price) { Add-Line $report (" - Precio: {0}" -f $card.Price) }
        if ($card.OldPrice) { Add-Line $report (" - Precio anterior: {0}" -f $card.OldPrice) }
        if ($card.Note) { Add-Line $report (" - Nota: {0}" -f $card.Note) }
        if ($card.DetailHref) { Add-Line $report (" - Detalle: {0}" -f $card.DetailHref) }
        if ($card.WhatsApp) { Add-Line $report (" - WhatsApp: {0}" -f $card.WhatsApp) }
        Add-Line $report ''
        $n++
      }
      continue
    }

    if ($hasCategoryCards) {
      Add-Line $report 'Tipo: vista de categorías / enlaces temáticos.'
      Add-Line $report ''
      $n = 1
      foreach ($chunk in $chunks) {
        if ($chunk -notmatch 'Ver productos') { continue }
        $card = Extract-CategoryCard $chunk
        Add-Line $report ("Categoría {0}:" -f $n)
        if ($card.Title) { Add-Line $report (" - Nombre: {0}" -f $card.Title) }
        if ($card.Image) { Add-Line $report (" - Imagen: {0}" -f $card.Image) }
        if ($card.Alt) { Add-Line $report (" - Alt imagen: {0}" -f $card.Alt) }
        if ($card.Description) { Add-Line $report (" - Descripción: {0}" -f $card.Description) }
        if ($card.Cta) { Add-Line $report (" - CTA: {0}" -f $card.Cta) }
        if ($card.Href) { Add-Line $report (" - Enlace: {0}" -f $card.Href) }
        Add-Line $report ''
        $n++
      }
      continue
    }
  }

  Add-Line $report 'Sin tarjetas de catálogo detectadas en esta vista.'
  Add-Line $report ''
}

Set-Content -LiteralPath $outFile -Value ($report -join [Environment]::NewLine) -Encoding UTF8
Write-Host ("Generado: {0}" -f $outFile)
