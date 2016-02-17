var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

module.exports = function(utils) {
  var Record, Store;
  Record = (function() {
    function Record(options) {
      this.links = options.links, this.meta = options.meta, this.id = options.id, this.type = options.type, this.attributes = options.attributes, this.relationships = options.relationships;
    }

    return Record;

  })();
  return Store = (function() {
    function Store(options) {
      this.syncWithMeta = bind(this.syncWithMeta, this);
      var base, base1, base2;
      this.options = utils.clone(options) || {};
      if ((base = this.options).addLinks == null) {
        base.addLinks = false;
      }
      if ((base1 = this.options).addMeta == null) {
        base1.addMeta = false;
      }
      if ((base2 = this.options).throwWarning == null) {
        base2.throwWarning = false;
      }
      this.reset();
    }

    Store.prototype.reset = function() {
      this.records = [];
      return this.relations = {};
    };

    Store.prototype.toModel = function(rec, type, models) {
      var addLinks, addMeta, base, data, key, links, lkey, lval, meta, mkey, model, mval, name, ref, ref1, ref2, rel, resolve;
      model = utils.clone(rec.attributes) || {};
      model.id = rec.id;
      model.type = rec.type;
      models[type] || (models[type] = {});
      (base = models[type])[name = rec.id] || (base[name] = model);
      addMeta = (function(_this) {
        return function(mkey, mval) {
          if (_this.options.addMeta && (mval != null)) {
            if (model.meta == null) {
              model.meta = {};
            }
            if (model.meta[mkey] && _this.options.throwWarning) {
              throw new Error('Meta-key ' + mkey + ' already defined by root record!');
            }
            return model.meta[mkey] = mval;
          }
        };
      })(this);
      addLinks = (function(_this) {
        return function(lkey, lval) {
          if (_this.options.addLinks && (lval != null)) {
            if (model.links == null) {
              model.links = {};
            }
            if (model.links[lkey] && _this.options.throwWarning) {
              throw new Error('Link-key ' + lkey + ' already defined by root record!');
            }
            return model.links[lkey] = lval;
          }
        };
      })(this);
      if (rec.meta != null) {
        ref = rec.meta;
        for (mkey in ref) {
          mval = ref[mkey];
          addMeta(mkey, mval);
        }
      }
      if (rec.links != null) {
        ref1 = rec.links;
        for (lkey in ref1) {
          lval = ref1[lkey];
          addLinks(lkey, lval);
        }
      }
      if (rec.relationships != null) {
        ref2 = rec.relationships;
        for (key in ref2) {
          rel = ref2[key];
          data = rel.data;
          links = rel.links;
          meta = rel.meta;
          if (this.options.addMeta && (meta != null)) {
            addMeta(key, meta);
          }
          if (this.options.addLinks && (links != null)) {
            addLinks(key, links);
          }
          model[key] = null;
          if (data == null) {
            continue;
          }
          resolve = (function(_this) {
            return function(arg) {
              var id, type;
              type = arg.type, id = arg.id;
              return _this.find(type, id, models);
            };
          })(this);
          model[key] = data instanceof Array ? data.map(resolve) : data != null ? resolve(data) : {};
        }
      }
      return model;
    };

    Store.prototype.findRecord = function(type, id) {
      return utils.find(this.records, function(r) {
        return r.type === type && r.id === id;
      });
    };

    Store.prototype.findRecords = function(type) {
      return utils.filter(this.records, function(r) {
        return r.type === type;
      });
    };

    Store.prototype.find = function(type, id, models) {
      var rec;
      if (models == null) {
        models = {};
      }
      rec = this.findRecord(type, id);
      if (rec == null) {
        return null;
      }
      models[type] || (models[type] = {});
      return models[type][id] || this.toModel(rec, type, models);
    };

    Store.prototype.findAll = function(type, models) {
      var recs;
      if (models == null) {
        models = {};
      }
      recs = this.findRecords(type);
      if (recs == null) {
        return [];
      }
      recs.forEach((function(_this) {
        return function(rec) {
          models[type] || (models[type] = {});
          return _this.toModel(rec, type, models);
        };
      })(this));
      return utils.values(models[type]);
    };

    Store.prototype.remove = function(type, id) {
      var records, remove;
      remove = (function(_this) {
        return function(record) {
          var index;
          index = _this.records.indexOf(record);
          if (!(index < 0)) {
            return _this.records.splice(index, 1);
          }
        };
      })(this);
      if (id != null) {
        return remove(this.findRecord(type, id));
      } else {
        records = this.findRecords(type);
        return records.map(remove);
      }
    };

    Store.prototype.sync = function(body) {
      var models, recs, sync;
      sync = (function(_this) {
        return function(data) {
          var add;
          if (data == null) {
            return null;
          }
          add = function(obj) {
            var id, rec, type;
            type = obj.type, id = obj.id;
            _this.remove(type, id);
            rec = new Record(obj);
            _this.records.push(rec);
            return rec;
          };
          if (data instanceof Array) {
            return data.map(add);
          } else {
            return add(data);
          }
        };
      })(this);
      sync(body.included);
      recs = sync(body.data);
      if (recs == null) {
        return null;
      }
      models = {};
      if (recs instanceof Array) {
        return recs.map((function(_this) {
          return function(rec) {
            return _this.toModel(rec, rec.type, models);
          };
        })(this));
      } else {
        return this.toModel(recs, recs.type, models);
      }
    };

    Store.prototype.syncWithMeta = function(body) {
      var data, meta;
      data = this.sync(body);
      meta = body.meta || {};
      return {
        data: data,
        meta: meta
      };
    };

    return Store;

  })();
};
