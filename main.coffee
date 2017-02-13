
DocumentRef = (require './backend_intf.coffee').DocumentRef
#Backend = (require './inmem_backend.coffee').InMemBackend
Backend = (require './redis_backend.coffee').RedisBackend

backend = new Backend()

express = require('express')
bodyParser = require('body-parser')
app = express()

app.use(bodyParser.text())

r = express.Router()
API_PREFIX = '/api/ivds/v1'
API_PREFIX = ''
app.use(API_PREFIX, r)
#r = app.route('/api/ivds/v1')

r.get '/', (req, res) ->
  res.send('ivds online')

r.get '/currentversion/:collection/:documentId', (req, res) ->
  backend.currentversion new DocumentRef(req.params.collection, req.params.documentId, -1), (err, data) ->
    if err?
      return res.sendStatus(400, err)
    return res.send(data)

r.get '/:collection/:documentId', (req, res) ->
  backend.retrieve new DocumentRef(req.params.collection, req.params.documentId, -1), (err, data) ->
    if err?
      return res.sendStatus(400, err)
    return res.send(data)

r.get '/:collection/:documentId/:version', (req, res) ->
  backend.retrieve new DocumentRef(req.params.collection, req.params.documentId,  req.params.version), (err, data) ->
    if err?
      return res.sendStatus(400, err)
    return res.send(data)

r.post '/:collection/:documentId', (req, res) ->
  unless req.body?
    return res.sendStatus(400)
  console.dir req.body
  backend.store new DocumentRef(req.params.collection, req.params.documentId, -1), req.body, (err, data) ->
    if err?
      return res.status(400).send(err)
    return res.send(data)

app.listen 3000
console.log "Listening on 3000"
