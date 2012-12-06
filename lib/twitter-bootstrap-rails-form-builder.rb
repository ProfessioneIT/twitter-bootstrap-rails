module BootstrapFormBuilder
  module FormHelper
    [:form_for, :fields_for].each do |method|
      module_eval do
        define_method "bootstrap_#{method}" do |record, *args, &block|
          # add the TwitterBootstrap builder to the options
          options           = args.extract_options!
          options[:builder] = BootstrapFormBuilder::FormBuilder

          if method == :form_for
            options[:html] ||= {}
            options[:html][:class] ||= 'form-horizontal'
          end

          # call the original method with our overridden options
          send method, record, *(args << options), &block
        end
      end
    end
  end

  class FormBuilder < ActionView::Helpers::FormBuilder
    include FormHelper
    include ActionView::Helpers::TagHelper

    def get_error_text(object, field, options)
      if object.nil? || options[:hide_errors]
        ""
      else
        errors = object.errors[field.to_sym]
        if errors.empty? then "" else errors.first end
      end
    end

    def get_object_id(field, options)
      object = @template.instance_variable_get("@#{@object_name}")
      return options[:id] || object.class.name.underscore + '_' + field.to_s
    end

    def get_label(field, options)
      labelOptions = {:class => 'control-label'}.merge(options[:label_options] || {})
      text = options[:label] || labelOptions[:text] || nil
      options.delete(:label)
      options.delete(:label_options)
      labelTag = label(field, text, labelOptions)
    end

    def inline_help(options)
      return "" unless options[:help]
      text = options[:help]
      options.delete(:help)
      content_tag :span, text, :class => 'help-inline'
    end

    def submit(value, options = {}, *args)
      super(value, {:class => "btn btn-primary"}.merge(options), *args)
    end

    def jquery_date_select(field, options = {})
      id = get_object_id(field, options)

      date =
          if options['start_date']
            options['start_date']
          elsif object.nil?
            Date.now
          else
            object.send(field.to_sym)
          end

      date_picker_script = "<script type='text/javascript'>" +
          "$( function() { " +
          "$('##{id}')" +
          ".datepicker( $.datepicker.regional[ 'en-NZ' ] )" +
          ".datepicker( 'setDate', new Date('#{date}') ); } );" +
          "</script>"
      return basic_date_select(field, options.merge(javascript: date_picker_script))
    end

    def basic_date_select(field, options = {})
      placeholder_text = options[:placeholder_text] || ''
      id = get_object_id(field, options)

      errorText = get_error_text(object, field, options)
      wrapperClass = 'control-group' + (errorText.empty? ? '' : ' error')
      errorSpan = if errorText.empty? then "" else "<span class='help-inline'>#{errorText}</span>" end

      labelTag = get_label(field, options)

      date =
          if options[:start_date]
            options[:start_date]
          elsif object.nil?
            Date.now.utc
          else
            object.send(field.to_sym)
          end

      javascript = options[:javascript] ||
          "
  <script>
    $(function() { 
      var el = $('##{id}');
      var currentValue = el.val();
      if(currentValue.trim() == '') return;
      el.val(new Date(currentValue).toString('dd MMM, yyyy'));
    });
  </script>"

      ("<div class='#{wrapperClass}'>" +
          labelTag +
          "<div class='controls'>" +
          super_text_field(field, {
              :id => id, :placeholder => placeholder_text, :value => date.to_s,
              :class => options[:class]
          }.merge(options[:text_field] || {})) +
          errorSpan +
          javascript +
          "</div>" +
          "</div>").html_safe
    end

    def jquery_datetime_select(field, options = {})
      id = get_object_id(field, options)

      date_time =
          if options['start_time']
            options['start_time']
          elsif object.nil?
            DateTime.now.utc
          else
            object.send(field.to_sym)
          end

      datetime_picker_script = "<script type='text/javascript'>" +
          "$( function() { " +
          "$('##{id}')" +
          ".datetimepicker( $.datepicker.regional[ 'en-NZ' ] )" +
          ".datetimepicker( 'setDate', new Date('#{date_time}') ); } );" +
          "</script>"
      return basic_datetime_select(field, options.merge(javascript: datetime_picker_script))
    end

    def basic_datetime_select(field, options = {})
      placeholder_text = options[:placeholder_text] || ''
      id = get_object_id(field, options)

      errorText = get_error_text(object, field, options)
      wrapperClass = 'control-group' + (errorText.empty? ? '' : ' error')
      errorSpan = if errorText.empty? then "" else "<span class='help-inline'>#{errorText}</span>" end

      labelTag = get_label(field, options)

      date_time =
          if options[:start_time]
            options[:start_time]
          elsif object.nil?
            DateTime.now.utc
          else
            object.send(field.to_sym)
          end

      javascript = options[:javascript] ||
          "
  <script>
    $(function() { 
      var el = $('##{id}');
      var currentValue = el.val();
      if(currentValue.trim() == '') return;
      el.val(new Date(currentValue).toString('dd MMM, yyyy HH:mm'));
    });
  </script>"

      ("<div class='#{wrapperClass}'>" +
          labelTag +
          "<div class='controls'>" +
          super_text_field(field, {
              :id => id, :placeholder => placeholder_text, :value => date_time.to_s,
              :class => options[:class]
          }.merge(options[:text_field] || {})) +
          errorSpan +
          javascript +
          "</div>" +
          "</div>").html_safe
    end

    def control_opening_html
      labelTag = get_label(@field, @options)
      errorText = get_error_text(@object, @field, @options)
      wrapperClass = 'control-group' + (errorText.empty? ? '' : ' error')

      #-- Build up the opening html to wrap everything in Twitter control Bootstap markup
      ("<div class='#{wrapperClass}'>" +
          labelTag +
          "<div class='controls'>")
    end

    def control_closing_html(help_block)
      errorText = get_error_text(@object, @field, @options)
      errorSpan = if errorText.empty? then "" else "<span class='help-inline'>#{errorText}</span>" end

      #-- Build up the return string
      ( inline_help(@options) +
        errorSpan +
        (help_block ? @template.capture(&help_block) : "") +
        "</div>" +
      "</div>")
    end

    basic_helpers = %w{text_field text_area file_field select email_field password_field number_field collection_select}
    multipart_helpers = %w{date_select datetime_select}
    trailing_label_helpers = %w{check_box}

    basic_helpers.each do |name|
      define_method(name) do |field, *args, &help_block|
        @field = field
        @options = args.last.is_a?(Hash) ? args.last : {}
        @object = @template.instance_variable_get("@#{@object_name}")

        ( control_opening_html() +
          super(field, *args) +
          control_closing_html(help_block)
        ).html_safe
      end
    end

    multipart_helpers.each do |name|
      define_method(name) do |field, *args, &help_block|
        @field = field
        @options = args.last.is_a?(Hash) ? args.last : {}
        @object = @template.instance_variable_get("@#{@object_name}")
        @options[:class] = 'inline ' + options[:class] if options[:class]

        ( control_opening_html() +
          super(field, *args) +
          control_closing_html()
        ).html_safe
      end
    end

    trailing_label_helpers.each do |name|
      # First alias old method
      class_eval("alias super_#{name.to_s} #{name}")

      define_method(name) do |field, *args, &help_block|
        options = args.first.is_a?(Hash) ? args.first : {}
        object = @template.instance_variable_get("@#{@object_name}")

        labelOptions = {:class => 'checkbox'}.merge(options[:label_options] || {})
        labelOptions["for"] = "#{@object_name}_#{field}"
        label_text = options[:label] || labelOptions[:text] || field.to_s.capitalize.gsub('_', ' ')
        options.delete(:label)
        options.delete(:label_options)

        errorText = get_error_text(object, field, options)

        wrapperClass = 'control-group' + (errorText.empty? ? '' : ' error')
        errorSpan = if errorText.empty? then "" else "<span class='help-inline'>#{errorText}</span>" end
        description = if options[:description] then %{<label class="control-label">#{options[:description]}</label>} else "" end
        options.delete(:description)
        ("<div class='#{wrapperClass}'>" +
            description +
            "<div class='controls'>" +
            tag(:label, labelOptions, true) +
            super(field, *args) +
            inline_help(options) +
            errorSpan +
            (help_block ? @template.capture(&help_block) : "") +
            label_text +
            "</label>" +
            "</div>" +
            "</div>"
        ).html_safe
      end
    end

  end
end
