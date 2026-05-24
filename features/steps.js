const { Given, When, Then } = require('@cucumber/cucumber');
const axios = require('axios');
const assert = require('assert');

let lead;

Given('I send a lead with name {string} from {string}', async (name, source) => {
  const res = await axios.post('http://localhost:3000/leads', { name, source });
  lead = res.data;
});

Given('I have an existing lead', async () => {
  const res = await axios.post('http://localhost:3000/leads', {
    name: 'Test',
    source: 'whatsapp'
  });
  lead = res.data;
});

When('I assign a score of {int}', async (score) => {
  const res = await axios.post(`http://localhost:3000/leads/${lead.id}/score`, {
    score
  });
  lead = res.data;
});

Then('the system should create the lead with status {string}', (status) => {
  assert.equal(lead.status, status);
});

Then('the lead should be {string}', (status) => {
  assert.equal(lead.status, status);
});