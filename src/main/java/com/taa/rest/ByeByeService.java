
package com.taa.rest;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.core.Response;
 
@Path("/ByeWorld")
public class ByeByeService {
 
	@GET
	public Response getMsg(@PathParam("param") String msg) {
 
		String output = "Bye world: from TAA";
 
		return Response.status(200).entity(output).build();
 
	}
 
}