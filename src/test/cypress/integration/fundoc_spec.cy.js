/* global cy */
/// <reference types="cypress" />

context('Function Documentation', () => {
  before (() => {
      // Generate function documentation before running tests
      cy.timeout(10000);
      cy.request({
        url: '/regenerate',
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
        // .its('body')
        // .should('equal', "{ status: 'ok', message: 'Scan completed! ' }")
  })

  beforeEach(() => {
    cy.visit('')
  })

  describe('landing page', () => {
    it('should contain major parts', () => {
      cy.get('.navbar')
        .contains('Home')
      cy.get('h1')
        .contains('Function Documentation')
      cy.get('#fun-query-form')
        .should('exist')
    })
  })

  describe('simple search', () => {
    it('should find article with extended markdown contents and code highlighting', () => {
      cy.get('#query-field')
        .type('file:sync{enter}')
      cy.get('.function-head')
        .should('exist')
        .click()
      cy.url()
        .should('include', 'q=file')
      // code is highlighted
      cy.get('.language-xquery')
        .should('exist')
      // button is visible
      cy.get('.extended-docs')
        .should('exist')
        .click()
      // displays MD 
      cy.get('zero-md')
        .should('exist')
    })
  })

  describe('browse', () => {
    it('should find local modules', () => {
      cy.get('#browse')
        .click()
      cy.get('.form-inline > .btn')
        .should('be.visible')
      cy.get('[name=appmodules]')
        .check()
      cy.get('.form-inline > .btn')
        .click()
      // check module from fundocs itself 
      cy.get('#modules')
        .contains('http://exist-db.org/apps/fundocs/generate')
        .click()
      cy.get('.module')
        .should('exist')
    })
  })
})
