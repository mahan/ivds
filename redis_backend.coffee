
bi = require './backend_intf.coffee'
Redis = require 'redis'
diff = require 'diff'
async = require 'async'

DocumentRef = bi.DocumentRef
BackendIntf = bi.BackendIntf

redis_key = (documentRef) ->
  return "#{documentRef.collection}#{documentRef.documentId}"

class RedisBackend extends BackendIntf

  @redis = null

  constructor: (@host, @port) ->
    RedisBackend.redis = Redis.createClient({host: @host | '127.0.0.1', port: @port | 6379});

  store: (documentRef, documentBody, fn) ->
    unless documentRef.version == -1
      return fn("InMemBackend.store() - Version must be -1, i.e. undefined, but is: #{documentRef.version}. Version is generated during the store()")
    r = RedisBackend.redis
    r.get "#{redis_key(documentRef)}.versioncounter", (err, data) ->
      if err?
        return fn(err)
      #Determine previous version. 0 = no old version exists
      oldVersion = 0
      if data?
        oldVersion = parseInt(data)
      #Try to read old version of the document.
      r.get "#{redis_key(documentRef)}", (err, data) ->
        if err?
          return fn(err)
        dbWork = []
        if data?
          dbWork.push (fn) ->
            patch = diff.createPatch('', documentBody, data, '', '', {context: 1})
            #NX makes this fail if there is a collision, between two flows
            r.set "#{redis_key(documentRef)}.#{oldVersion}", patch, "NX", (err, data) ->
              if err?
                return fn(err)
              unless data?
                return fn("Unable to write old version. Two or more requests for storing probably collided.")
              return fn()
        dbWork.push (fn) ->
          r.set "#{redis_key(documentRef)}.versioncounter", "#{oldVersion+1}", (err, data) ->
            return fn(err)
        dbWork.push (fn) ->
          r.set "#{redis_key(documentRef)}", documentBody, (err) ->
            return fn(err)
        async.series dbWork, (err) ->
          if err?
            return fn(err)
          documentRef.version = oldVersion+1
          return fn(null, documentRef)

  retrieve: (documentRef, fn) ->
    r = RedisBackend.redis
    @currentversion documentRef, (err, _dr) ->
      currVersion = _dr.version
      r.get "#{redis_key(documentRef)}", (err, data) ->
        if err?
          return fn(err)
        unless data?
          return fn("no document matching documentRef = #{redis_key(documentRef)} found.")
        currentVersionData = data
        if documentRef.version == -1 || documentRef.version == currVersion #get latest version
            documentRef.version = currVersion
            return fn(null, {documentRef: documentRef, documentBody: currentVersionData})
        else #Specific older version
          if documentRef.version < 1 or documentRef.version >= currVersion
            return fn("#{JSON.stringify(documentRef)}, bad version requested.")
          listOfVersions = (v for v in [documentRef.version...currVersion])
          #console.log JSON.stringify listOfVersions
          #throw new Exception("lol")
          dbWork = []
          for v in listOfVersions.reverse()
            dbWork.push do ->
              _v = v
              return (fn) ->
                r.get "#{redis_key(documentRef)}.#{_v}", (err, data) ->
                  if err?
                    return fn(err)
                  return fn(null, data)
          async.parallel dbWork, (err, data) ->
            if err?
              return fn(err)
            d = currentVersionData
            for patch in data
              #console.log "d = '#{d}'"
              d = diff.applyPatch(d, patch)
            #console.log "d = '#{d}'"
            return fn(null, {documentRef: documentRef, documentBody: d.trim()}) #TODO: Understand why new-lines are added per version at end-of-file. Now just .trim()

  currentversion: (documentRef, fn) ->
    documentRef = JSON.parse(JSON.stringify(documentRef)) # Copy so we don't manipulate sent in documentRef
    r = RedisBackend.redis
    r.get "#{redis_key(documentRef)}.versioncounter", (err, data) ->
      if err?
        return fn(err)
      unless data?
        return fn("#{redis_key(documentRef)}.versioncounter not found.")
      documentRef.version = parseInt(data)
      return fn(null, documentRef)

module.exports = {
  RedisBackend
}
