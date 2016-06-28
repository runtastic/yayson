module.exports = (utils) ->
  class Record
    constructor: (options) ->
      {@links, @meta, @id, @type, @attributes, @relationships} = options

  class Store
    constructor: (options) ->
      @options = utils.clone(options) || {}

      @options.addLinks ?= false
      @options.addMeta ?= false
      @options.throwWarning ?= false
      @options.keepEmptyRelationships ?= false

      @reset()

    reset: ->
      @records = []
      @relations = {}

    toModel: (rec, type, models) ->
      model = utils.clone(rec.attributes) || {}
      model.id = rec.id
      model.type = rec.type
      models[type] ||= {}
      models[type][rec.id] ||= model

      addMeta = (mkey, mval) =>
        if @options.addMeta and mval?
          model.meta ?= {}
          if model.meta[mkey] and @options.throwWarning
            throw new Error('Meta-key ' + mkey + ' already defined by root record!')
          model.meta[mkey] = mval

      addLinks = (lkey, lval) =>
        if @options.addLinks and lval?
          model.links ?= {}
          if model.links[lkey] and @options.throwWarning
            throw new Error('Link-key ' + lkey + ' already defined by root record!')
          model.links[lkey] = lval

      if rec.meta?
        for mkey, mval of rec.meta
          addMeta mkey, mval

      if rec.links?
        for lkey, lval of rec.links
          addLinks lkey, lval

      if rec.relationships?
        for key, rel of rec.relationships
          data = rel.data
          links = rel.links
          meta = rel.meta

          if @options.addMeta and meta?
            addMeta key, meta

          if @options.addLinks and links?
            addLinks key, links

          model[key] = null

          continue unless data?
          resolve = ({type, id}) =>
            @find type, id, models
          model[key] = if data instanceof Array
            data.map resolve
          else if data?
            resolve data
          else
            {}

      model

    findRecord: (type, id) ->
      utils.find @records, (r) ->
        r.type == type && r.id == id

    findRecords: (type) ->
      utils.filter @records, (r) ->
        r.type == type

    find: (type, id, models = {}) ->
      rec = @findRecord(type, id)
      return null unless rec?
      models[type] ||= {}
      models[type][id] || @toModel(rec, type, models)

    findAll: (type, models = {}) ->
      recs = @findRecords(type)
      return [] unless recs?
      recs.forEach (rec) =>
        models[type] ||= {}
        @toModel(rec, type, models)
      utils.values models[type]

    remove: (type, id) ->
      remove = (record) =>
        index = @records.indexOf record
        @records.splice(index, 1) unless index < 0

      if id?
        remove @findRecord(type, id)
      else
        records = @findRecords type
        records.map remove

    sync: (body) ->
      sync = (data) =>
        if data?
          if @options.keepEmptyRelationships then return { id } else return null
        add = (obj) =>
          {type, id} = obj
          @remove type, id
          rec = new Record(obj)
          @records.push rec
          rec

        if data instanceof Array
          data.map add
        else
          add data

      sync body.included

      recs = sync body.data

      return null unless recs?

      models = {}
      if recs instanceof Array
        recs.map (rec) =>
          @toModel rec, rec.type, models
      else
        @toModel recs, recs.type, models

    syncWithMeta: (body) =>
      data = @sync body
      meta = body.meta || {}

      return { data, meta }

