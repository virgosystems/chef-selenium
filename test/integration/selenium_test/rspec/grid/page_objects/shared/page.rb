# Awful Valentine Page
class Page
  def initialize(selenium)
    @selenium = selenium
    verify(@selenium)
  end

  def header
    Header.new(@selenium)
  end

  def body
    Body.new(@selenium)
  end

  def sidebar
    Sidebar.new(@selenium)
  end

  def footer
    Footer.new(@selenium)
  end

  def verify(selenium)
    return unless URI.parse(selenium.current_url).path != page_path
    fail "Unexpected page. Expected #{page_path} but full path was #{selenium.current_url}"
  end
end
