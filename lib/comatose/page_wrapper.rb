# This class wraps the ComatosePage
# Model to prevent access directly to the "page" from the Liquid
# drop.
#
class Comatose::PageWrapper

  ##
  ## These methods go directly to the page.
  ##
  @@allowed_methods = %w(id  full_path uri title slug
                         keywords to_html
                         filter_type author updated_on created_on)
  ##
  ## These methods are intercepted/implemented here.
  ##
  @@custom_methods = %w(link page_photo page_photo_uri content parent next previous
                        children rchildren first_child
                        last_child has_keyword)

  attr_accessor :page
  private :page

  def initialize( page, locals={} )
    @page = page
    @keyword_lst = []
    @keyword_hsh = {}
    unless page.nil?
      @keyword_lst = (page.keywords || '').downcase.split(',').map {|k| k.strip }
      @keyword_lst.each {|kw| @keyword_hsh[kw] = true}
    end
    @locals = locals
  end

  def has_keyword?(keyword)
    @page.has_keyword?(keyword)
  end

  def has_keyword
    @keyword_hsh
  end

  #
  # This function intercepts and returns the image tag for the page_photo
  # via a hash on it's configured thumbnail names. For example, it's
  # use is {{ page_photo.thumb }}, {{ page_photo.small }}, etc.
  #
  def page_photo
    if @page.page_photo
      thumbnails = Comatose.config.page_photo['attachment_fu_options']['thumbnails']
      names = thumbnails.keys
      photos = {}
      view = ActionView::Base.new
      for name in names
        photos[name] = view.image_tag(@page.page_photo.public_filename(name))
      end
      photos
    end
  end

  #
  # This function intercepts and returns the local URI for the page_photo
  # via a hash on it's configured thumbnail names. For example, it's
  # use is {{ page_photo.thumb }}, {{ page_photo.small }}, etc.
  #
  def page_photo_uri
    if @page.page_photo
      thumbnails = Comatose.config.page_photo['attachment_fu_options']['thumbnails']
      names = thumbnails.keys
      uris = {}
      view = ActionView::Base.new
      for name in names
        uris[name] = view.url_for(@page.page_photo.public_filename(name))
      end
      uris
    end
  end

  def next
    @next_page ||= begin
      if @page.lower_item.nil?
        nil
      else
        Comatose::PageWrapper.new( @page.lower_item )
      end
    end
  end

  def previous
    @prev_page ||= begin
      if @page.higher_item.nil?
        nil
      else
        Comatose::PageWrapper.new( @page.higher_item )
      end
    end
  end

  def first_child
    children.first
  end

  def def last_child
    children.last
  end

  # Generates a link to this page... You can pass in the link text,
  # otherwise it will default to the page title.
  def link( title=nil )
    title = @page.title if title.nil?
    TextFilters[@page.filter_type].create_link(title, @page.uri)
  end

  def content
    @page.to_html( @locals )
  end

  def parent
    @parent ||= begin
      if @page.parent.nil?
        nil
      else
        Comatose::PageWrapper.new( @page.parent )
      end
    end
  end

  def children
    # Cache the results so that you can have multiple calls to #children without a penalty
    @children ||= @page.children.to_a.collect {|child| Comatose::PageWrapper.new( child, @locals )}
  end

  # Children, in reverse order
  def rchildren
    children.reverse
  end

  #
  # This is the entry function that the Liquid Drop calls for {{ page.* }}.
  #
  def [](key)
    if @@allowed_methods.include? key.to_s #or page.attributes.has_key? key.to_s
      @page.send( key )
    elsif @@custom_methods.include? key
      self.send(key.to_sym)
    end
  end

  def has_key?(key)
    @@allowed_methods.include? key or @@custom_methods.include? key
  end

  def to_s
    @page.title
  end

  def to_liquid
    self
  end

  def method_missing(method_id, *args)
    #puts "Looking for method: #{method_id} (#{method_id.class.to_s}) in [#{@@allowed_methods.join(', ')}] or [#{@page.attributes.keys.join(', ')}]"
    if @@allowed_methods.include? method_id.to_s or @page.attributes.has_key? method_id.to_s
      @page.send( method_id, *args)
    else
      # Access nazi says: NO ACCESS FOR YOU!!
      # but he says it silently...
    end
  end

end
