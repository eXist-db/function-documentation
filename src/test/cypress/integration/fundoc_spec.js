/* global cy */
/// <reference types="cypress" />

context('Function Documentation', () => {
  beforeEach(() => {
    cy.visit('')
    // TODO: Generate index in beforeAll
  })
  describe('landing page', () => {
    it('should show heading', () => {
      cy.get('h1')
        .contains('Function Documentation')
    })
  })  
})
