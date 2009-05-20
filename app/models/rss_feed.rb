class RssFeed < Article

  # i dont know why before filter dont work here
  def initialize(*args)
    super(*args)
    self.advertise = false
  end

  # store setting in body
  serialize :body, Hash
  
  def body
    self[:body] ||= {}
  end
  alias :settings :body

  # The maximum number of articles to be displayed in the RSS feed. Default: 10
  def limit
    settings[:limit] || 10
  end
  def limit=(value)
    settings[:limit] = value
  end

  # FIXME this should be validates_numericality_of, but Rails 2.0.2 does not
  # support validates_numericality_of with virtual attributes
  validates_format_of :limit, :with => /^\d+$/, :if => :limit

  # determinates what to include in the feed. Possible values are +:all+
  # (include everything from the profile) and :parent_and_children (include
  # only articles that are siblings of the feed).
  #
  # The feed itself is never included.
  def include
    settings[:include]
  end
  def include=(value)
    settings[:include] = value
  end
  validates_inclusion_of :include, :in => [ 'all', 'parent_and_children' ], :if => :include

  # determinates what to include in the feed as items' description. Possible
  # values are +:body+ (default) and +:abstract+.
  def feed_item_description
    settings[:feed_item_description]
  end
  def feed_item_description=(value)
    settings[:feed_item_description] = value
  end
  validates_inclusion_of :feed_item_description, :in => [ 'body', 'abstract' ], :if => :feed_item_description

  # TODO
  def to_html(options = {})
  end

  # RSS feeds have type =text/xml=.
  def mime_type
    'text/xml'
  end

  include ActionController::UrlWriter
  def fetch_articles
    if parent && parent.blog?
      return parent.posts.find(:all, :conditions => ['published = ?', true], :limit => self.limit, :order => 'id desc')
    end

    articles =
      if (self.include == 'parent_and_children') && self.parent
        self.parent.map_traversal
      else
        profile.recent_documents(self.limit)
      end
  end
  def data
    articles = fetch_articles

    result = ""
    xml = Builder::XmlMarkup.new(:target => result)

    xml.instruct! :xml, :version=>"1.0" 
    xml.rss(:version=>"2.0") do
      xml.channel do
        xml.title(_("%s's RSS feed") % (self.profile.name))
        xml.link(url_for(self.profile.url))
        xml.description(_("%s's content published at %s") % [self.profile.name, self.profile.environment.name])
        xml.language("pt_BR")
        for article in articles
          unless self == article
            xml.item do
              xml.title(article.name)
              if self.feed_item_description == 'body'
                xml.description(article.body)
              else
                xml.description(article.abstract)
              end
              # rfc822
              xml.pubDate(article.created_at.rfc2822)
              # link to article
              xml.link(url_for(article.url))
              xml.guid(url_for(article.url))
            end
          end
        end
      end
    end

    result
  end

  def self.short_description
    _('RSS Feed')
  end

  def self.description
    _('Provides a news feed of your more recent articles.')
  end

  def icon_name
    'rss-feed'
  end

  def can_display_hits?
    false
  end

end
