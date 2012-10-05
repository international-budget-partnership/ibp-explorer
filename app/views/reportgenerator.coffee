template = require 'views/templates/reportgenerator'

class ReportGenerator extends Backbone.View

    ##################
    ## Public methods
    ##################
    setInitialState: =>
        @$el.find('#group-0').click()

    render: (target) =>
        renderData = 
            groupings0: _EXPLORER_DATASET.groupings.slice(0,3)
            groupings1: _EXPLORER_DATASET.groupings.slice(3,5)
            question: ( _EXPLORER_DATASET.question[x] for x of _EXPLORER_DATASET.question )
            country: _EXPLORER_DATASET.country
        # Write to DOM
        @$el.html template renderData
        target.empty().append @$el

        @$el.find('.group-toggler').bind 'mouseover', @_hoverGroupToggle
        @$el.find('.group-toggler').bind 'click', @_clickGroupToggle
        @$el.find('.group-toggler').bind 'mouseout', (e) =>
            @$el.find('.toggle-box').removeClass 'hover'
        @$el.find('.toggle-box').bind 'click', @_clickBoxToggle
        #@$el.find('.toggle-box').bind 'mouseover', @_showQuestion
        #@$el.find('.toggle-box').bind 'mouseout', @_hideQuestion
        @$el.find('.expand-collapse a').bind 'click', @_expand_collapse
        @$el.find('.select-or-clear button').bind 'click', @_select_or_clear
        @$el.find('.toggle-box').tooltip
            placement: 'left'
            delay: 100
            animatoin: true

    ##################
    ## Private methods
    ##################
    _updated: =>
        @questionSet = []
        el = $('.toggle-box.select')
        for e in (el or [])
            @questionSet.push parseInt $(e).attr('id').substr(7)
        # Inner function
        calculateScore = (db) =>
            if @questionSet.length==0 then return 0
            acc = 0
            count = 0
            for x in @questionSet
                if db[x] >= 0
                    acc += db[x]
                    count++
            if (count==0) then return 0
            return Math.round( acc / count )
        # Calculate dataset of countries and scores
        @dataset = []
        for country in _EXPLORER_DATASET.country
            obj = 
                country: country.name
                alpha2: country.alpha2
            for year in [2006,2008,2010,2012]
                if not (('db_'+year) of country) then continue
                score = calculateScore country['db_'+year], @questionSet
                obj[year] = score
            @dataset.push obj
        @trigger('update', @dataset, @questionSet)

    _select_or_clear: (e) =>
        @_setSubtitle()
        @$el.find('.group-toggler').removeClass 'active'
        el = $(e.delegateTarget)
        if el.hasClass 'select'
            $('.toggle-box').addClass 'select'
        else if el.hasClass 'clear'
            $('.toggle-box').removeClass 'select'
        @_updated()

    _expand_collapse: (e) =>
        e.preventDefault()
        if ($(e.delegateTarget).hasClass 'more-options')
            @$el.find('.more-options').hide()
            @$el.find('.less-options').show()
            @$el.find('.inner').show()
        else if ($(e.delegateTarget).hasClass 'less-options')
            @$el.find('.more-options').show()
            @$el.find('.less-options').hide()
            @$el.find('.inner').hide()
        @trigger 'resize'
        return false

    _setSubtitle: (title='Custom Report') =>
        @$el.find('.subtitle').html(title)

    _hoverGroupToggle: (e) ->
        el = $(e.delegateTarget)
        group = el.attr('id')
        $('#toggle-boxes .'+group).addClass 'hover'

    _clickGroupToggle: (e) =>
        e.preventDefault()
        el = $(e.delegateTarget)
        group = el.attr('id')
        @$el.find('.group-toggler').removeClass 'active'
        el.addClass 'active'
        @_setSubtitle el.text()
        x = @$el.find('#toggle-boxes')
        x.find('.toggle-box').removeClass 'select'
        x.find(' .'+group).addClass 'select'
        @_updated()
        return false

    _clickBoxToggle: (e) =>
        e.preventDefault()
        el = $(e.delegateTarget)
        if el.hasClass 'select'
            el.removeClass 'select'
        else
            el.addClass 'select'
        @_setSubtitle()
        @$el.find('.group-toggler').removeClass 'active'
        @_updated()
        return false


    ###
    _showQuestion: (e) ->
        el = $(e.delegateTarget)
        id = el.attr('id')
        assert id.substr(0,7) is 'toggle-'
        id = parseInt id.substr(7)
        q_box = $('#question-view')
        q_box.html 'question '+id
        q_box.show()

    _hideQuestion: (e) ->
        q_box = $('#question-view')
        q_box.hide()
    ###

module.exports = new ReportGenerator()

###
    clickExpand: (e) ->
        e.preventDefault()
        $(e.currentTarget).parents('.text').first().trigger 'destroy'
        return false

# In render():
        # Bind to DOM
        $('.question .text').each (i,el) =>
            el = $(el)
            el.dotdotdot {
                height: 60
                after: 'a.expand'
                ellipsis: '  '
                callback: (isTruncated) =>
                    expandLink = el.find('a.expand')
                    if isTruncated
                        expandLink.click @clickExpand
                    else
                        expandLink.remove()
            }
            el.bind 'destroy', (e) -> el.find('a.expand').remove()
###
