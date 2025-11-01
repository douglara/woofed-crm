module ApplicationHelper
  include Pagy::Frontend

  def embedded_svg(filename, options = {})
    assets = Rails.application.assets
    asset = assets.find_asset(filename)

    if asset
      file = asset.source.force_encoding("UTF-8")
      doc = Nokogiri::HTML::DocumentFragment.parse file
      svg = doc.at_css "svg"
      svg["class"] = options[:class] if options[:class].present?
    else
      doc = "<!-- SVG #{filename} not found -->"
    end

    raw doc
  end

  def with_transparency(color, alpha = '40')
    return color unless color.present?
    
    # Remove espa?os e converte para mai?sculas
    color = color.strip.upcase
    
    # Se j? tiver alpha (8 caracteres hex), substitui
    if color.match?(/^#[0-9A-F]{8}$/)
      return color[0..6] + alpha
    end
    
    # Se for hex de 6 caracteres, adiciona alpha
    if color.match?(/^#[0-9A-F]{6}$/)
      return color + alpha
    end
    
    # Se for hex de 3 caracteres, expande e adiciona alpha
    if color.match?(/^#[0-9A-F]{3}$/)
      expanded = color.chars.map { |c| c + c }.join
      return '#' + expanded[1..6] + alpha
    end
    
    # Se for rgb/rgba, converte para hex com alpha
    if color.start_with?('rgb')
      # Extrai valores RGB
      rgb_match = color.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/)
      if rgb_match
        r = rgb_match[1].to_i
        g = rgb_match[2].to_i
        b = rgb_match[3].to_i
        hex = sprintf("#%02X%02X%02X", r, g, b)
        return hex + alpha
      end
    end
    
    # Se n?o conseguir converter, retorna a cor original com alpha
    # Tenta adicionar # se n?o tiver
    color = '#' + color unless color.start_with?('#')
    return color + alpha if color.length == 7
    return color
  end
end
