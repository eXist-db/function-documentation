context('Regenerating function documentation', () => {
  it('succeeds', () => {
      cy.timeout(10000); // generation needs some time
      cy.request({
        url: 'http://127.0.0.1:8080/exist/apps/fundocs/regenerate',
        auth: {
          user: 'admin', 
          password: ''
        }
      })
        .then((response) => {
          expect(response).to.have.property('status')
          expect(response.status).to.equal(200)
          expect(response.body).to.have.property('status')
          expect(response.body.status).to.equal('ok')
        })
  })
})
