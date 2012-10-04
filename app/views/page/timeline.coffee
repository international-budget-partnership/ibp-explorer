template_page = require 'views/templates/page/timeline'
template_timeline_column = require 'views/templates/timeline_column'

reportGenerator = require 'views/reportgenerator'

module.exports = class TimelinePage extends Backbone.View

    ##################
    ## Public methods
    ##################
    renderPage: (target) =>
        # Write to DOM
        @$el.html template_page()
        target.html @$el
        # Bind to on-page elements
        $('#timeline-toggle-button').toggleButtons
            onChange: @_onToggleMode
            width: 136
            style:
                enabled: 'primary'
                disabled: 'success'
            label: 
                enabled: "Rank"
                disabled: "Score"
        reportGenerator.bind 'update', @_updateReport
        reportGenerator.bind 'resize', @_redrawJsPlumb
        @_updateReport()

    ##################
    ## Private methods
    ##################
    _onToggleMode: (el,@showRank=true) =>
        if @showRank
            $('.timeline-cell-score').hide()
            $('.timeline-cell-rank').show()
        else
            $('.timeline-cell-rank').hide()
            $('.timeline-cell-score').show()

    _calculateScore: (db, questionSet) ->
        if questionSet.length==0 then return 0
        acc = 0
        count = 0
        for x in questionSet
            if db[x] >= 0
                acc += db[x]
                count++
        return Math.round( acc / count )

    _buildRankingTable: (year, questionSet) =>
        # Basic dataset
        out = []
        for country in _EXPLORER_DATASET.country
            if not (('db_'+year) of country) then continue
            score = @_calculateScore country['db_'+year], questionSet
            out.push 
                country: country.name
                alpha2: country.alpha2
                score: score
        out.sort @_sortFunction
        # Add 'rank' field
        rank = 0
        latest = 999
        n = 0
        tag_duplicates = []
        for x in out
            n += 1
            if x.score < latest
                latest = x.score
                rank = n
            else
                tag_duplicates.push x.score
            x.rank = rank
        # Append an equals sign where scores are neck-and-neck
        for x in out
            if x.score in tag_duplicates
                x.rank = '= '+x.rank
        return out

    _sortFunction: (a,b) ->
        x = b.score - a.score 
        if not x
            return a.country.localeCompare b.country
        return x

    _updateReport: =>
        questionSet = reportGenerator.questionSet()
        # PreRender
        html = ''
        for year in [2006,2008,2010,2012]
            html += template_timeline_column
                year: year
                data: @_buildRankingTable(year, questionSet)
        # Large DOM rebuild here. Trigger a single reflow.
        $('#timeline-columns').html html
        $('#timeline-columns tr').bind 'mouseover', @_mouseoverRanking
        # Pre-select the top-most entrant in the latest results
        if not @mouseoverAlpha2
            @mouseoverAlpha2 = $('#timeline-column-2012 tbody tr:first-child').attr 'data-alpha2'
        @_redrawJsPlumb()
        # Show ranks or scores as appropriate
        @_onToggleMode null,@showRank

    _mouseoverRanking: (e) =>
        el = $(e.delegateTarget)
        alpha2 = el.attr('data-alpha2')
        if alpha2 
            @_redrawJsPlumb alpha2

    _redrawJsPlumb: (alpha2=null) =>
        if alpha2 then @mouseoverAlpha2 = alpha2
        @$el.find('.hover').removeClass 'hover'
        els = @$el.find('.timeline-row-'+@mouseoverAlpha2)
        if not els.length then return
        els.addClass 'hover'
        jsPlumb.deleteEveryEndpoint()
        # This is expensive, so hold off until the mouse has settled for a few ms
        if @timeout then clearTimeout @timeout
        @timeout = setTimeout( ->
            for x in [0...els.length-1]
                jsPlumb.connect {source: els[x], target: els[x+1], overlays: jsPlumb._custom_overlay}
            @timeout = null
        , 50)

        

