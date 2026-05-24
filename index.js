const express = require('express');
const bodyParser = require('body-parser');
const { middleware } = require('express-openapi-validator');

const app = express();
app.use(bodyParser.json());

app.use(
  middleware({
    apiSpec: './openapi.yaml',
    validateRequests: true,
    validateResponses: true,
  })
);

let leads = {};

app.post('/leads', (req, res) => {
  const id = Date.now().toString();
  const lead = { id, ...req.body, status: 'new', score: 0 };
  leads[id] = lead;
  res.json(lead);
});

app.post('/leads/:id/score', (req, res) => {
  const lead = leads[req.params.id];
  lead.score = req.body.score;

  if (lead.score >= 90) {
    lead.status = 'vip';
  } else if (lead.score > 70) {
    lead.status = 'qualified';
  }

  res.json(lead);
});

app.listen(3000, () => console.log('API running on 3000'));