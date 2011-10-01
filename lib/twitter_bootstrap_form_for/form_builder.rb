require 'twitter_bootstrap_form_for'

class TwitterBootstrapFormFor::FormBuilder < ActionView::Helpers::FormBuilder
  # TODO: support inline inputs
  
  include TwitterBootstrapFormFor::FormHelpers
  
  attr_reader :template
  attr_reader :object
  attr_reader :object_name
  
  INPUTS = [
    :select,
    *ActionView::Helpers::FormBuilder.instance_methods.grep(%r{_area$}),
    *ActionView::Helpers::FormBuilder.instance_methods.grep(%r{_button$}),
    *ActionView::Helpers::FormBuilder.instance_methods.grep(%r{_field$}),
    *ActionView::Helpers::FormBuilder.instance_methods.grep(%r{_select$}),
  ]
  
  TOGGLES = [
    :check_box,
    :radio_button,
  ]
  
  #
  # Wraps the contents of the block passed in a fieldset with optional
  # +legend+ text.
  #
  def inputs(legend = nil, &block)
    # TODO: don't wrap error fields in field_with_error divs
    # ActionView::Base.field_error_proc = ->(html_tag, instance) { html_tag }
  
    template.render(
      :layout => 'twitter_bootstrap_form_for/inputs',
      :locals => { :legend => legend },
      &block
    )
  end
  
  #
  # Wraps groups of toggles (radio buttons, checkboxes) with a single label
  # and the appropriate markup. All toggle buttons should be rendered
  # inside of here, and will not look correct unless they are.
  #
  def toggles(label = nil, &block)
    template.render(
      :layout => 'twitter_bootstrap_form_for/toggles',
      :locals => { :label => label },
      &block
    )
  end
  
  #
  # Wraps action buttons into their own styled container.
  #
  def actions(&block)
    template.content_tag(:div, :class => 'actions', &block)
  end
  
  #
  # Renders a submit tag with default classes to style it as a primary form
  # button.
  #
  def submit(value = nil, options = {})
    options[:class] ||= 'btn primary'
    
    super value, options
  end
  
  INPUTS.each do |input|
    define_method input do |attribute, *args, &block|
      options = args.extract_options!
      
      template.render(
        :layout => 'twitter_bootstrap_form_for/input',
        :locals => {
          :form      => self,
          :attribute => attribute,
          # only skip label if it's explicitly false
          :label     => args.first.nil? ? '' : args.shift,
          :add_on    => (options[:add_on] && 'input-' << options.delete(:add_on).to_s),
          :block     => block
        }
      ) { super attribute, *(args << options) }
    end
  end
  
  TOGGLES.each do |toggle|
    define_method toggle do |attribute, *args, &block|
      options = args.extract_options!
      
      template.render(
        :layout => 'twitter_bootstrap_form_for/toggle',
        :locals => {
          :form      => self,
          :attribute => attribute,
          :label     => args.first.nil? ? '' : args.shift,
          :id        => self.object_name.to_s + '_' + attribute.to_s,
        }
      ) { super attribute, *(args << options) }
    end
  end
  
  def div_wrapper(attribute, options = {}, &block)
    options[:id]    = _wrapper_id      attribute, options[:id]
    options[:class] = _wrapper_classes attribute, options[:class]
    
    template.content_tag(:div, options, &block)
  end
  
  def errors_on?(attribute)
    self.object.errors[attribute].present?
  end
  
  def errors_for(attribute)
    self.object.errors[attribute].try(:join, ', ')
  end
  
  private
  
  #
  # Returns an HTML id to uniquely identify the markup around an input field.
  # If a +default+ is provided, it uses that one instead.
  #
  def _wrapper_id(attribute, default = nil)
    default || [
      _object_name + _object_index, 
      _attribute_name(attribute),
      'input'
     ].join('_')
  end
  
  #
  # Returns any classes necessary for the wrapper div around fields for
  # +attribute+, such as 'errors' if any errors are present on the attribute.
  # This merges any +classes+ passed in.
  #
  def _wrapper_classes(attribute, *classes)
    classes.tap do |classes|
      classes.push 'error' if self.errors_on?(attribute)
    end
  end
  
  def _attribute_name(attribute)
    attribute.to_s.gsub(/[\?\/\-]$/, '')
  end
  
  def _object_name
    self.object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")
  end
  
  def _object_index
    case
      when options.has_key?(:index) then options[:index]
      when defined?(@auto_index)    then @auto_index
      else                               nil
    end.to_s
  end
end
